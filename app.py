# A backend server using only Python's built-in http.server module.
# This version serves BOTH the API and the HTML frontend.

import http.server
import socketserver
import json
import mysql.connector
from urllib.parse import urlparse
from datetime import datetime
from decimal import Decimal

# --- Configuration ---
# NOW WE HAVE TWO CONFIGS
db_config_admin = {
    'user': 'root',
    'password': 'more2314',
    'host': 'localhost',
    'port': 3306,
    'database': 'mini_project2'
}

db_config_user = {
    'user': 'general_user',
    'password': 'password123', # The password you created in MySQL
    'host': 'localhost',
    'port': 3306,
    'database': 'mini_project2'
}

# --- Helper Functions ---
def get_db_connection(role='User'):
    """
    Establishes a connection to the database
    BASED ON THE USER'S ROLE.
    """
    config = db_config_user
    if role == 'Admin':
        config = db_config_admin
        
    try:
        conn = mysql.connector.connect(**config)
        return conn
    except mysql.connector.Error as err:
        print(f"Error connecting to database as {role}: {err}")
        return None

def json_serial(obj):
    """JSON serializer for objects not serializable by default json code"""
    if isinstance(obj, datetime):
        return obj.isoformat()
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError ("Type %s not serializable" % type(obj))

# --- Custom Request Handler ---
class MyHttpRequestHandler(http.server.SimpleHTTPRequestHandler):
    
    # This dictionary will store the role of the logged-in user (identified by their IP only)
    session_roles = {}
    
    def get_user_key(self):
        # Use only IP address (not port) as the session key
        return self.client_address[0]
    
    def get_user_role(self):
        # Get the role for the person making this request
        user_key = self.get_user_key()
        role = self.session_roles.get(user_key, 'User')
        print(f"Getting role for {user_key}: {role}")  # Debug print
        return role

    def set_user_role(self, role):
        # Store the role for the person making this request
        user_key = self.get_user_key()
        print(f"Setting role for {user_key} to: {role}")
        self.session_roles[user_key] = role
        
    def _send_cors_headers(self):
        """Sends headers that allow cross-origin requests."""
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "X-Requested-With, Content-Type")

    def do_OPTIONS(self):
        """Handler for CORS preflight requests."""
        self.send_response(200, "ok")
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self):
        """Handler for GET requests."""
        parsed_path = urlparse(self.path)
        
        # All GET requests now use the user's role
        current_role = self.get_user_role()
        
        # 1. ROUTING FOR THE MAIN HTML PAGE
        if parsed_path.path == '/' or parsed_path.path == '/concert_ui.html':
            try:
                with open('concert_ui.html', 'rb') as f:
                    self.send_response(200)
                    self.send_header('Content-type', 'text/html')
                    self.end_headers()
                    self.wfile.write(f.read())
            except FileNotFoundError:
                self.send_response(404)
                self.send_header('Content-type', 'text/plain')
                self.end_headers()
                self.wfile.write(b'Error: concert_ui.html not found.')
        
        # 2. ROUTING FOR THE API DATA
        elif parsed_path.path.startswith('/api/data'):
            # We get a connection based on the user's role
            conn = get_db_connection(current_role)
            if not conn:
                self.send_response(500)
                self.send_header('Content-type', 'application/json')
                self._send_cors_headers()
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Database connection failed'}).encode())
                return

            try:
                cursor = conn.cursor(dictionary=True)
                
                cursor.execute("SELECT UserID, FName, LName, Role FROM Users")
                users = cursor.fetchall()
                
                cursor.execute("SELECT VenueID, VenueName FROM Venue")
                venues = cursor.fetchall()

                cursor.execute("""
                    SELECT 
                        e.*, 
                        v.VenueName, 
                        v.City,
                        GetEventTotalRevenue(e.EventID) AS TotalRevenue 
                    FROM Event e 
                    JOIN Venue v ON e.VenueID = v.VenueID
                """)
                events = cursor.fetchall()

                cursor.execute("SELECT OrgID, OrgName FROM Organisers")
                organisers = cursor.fetchall()

                cursor.execute("SELECT StaffID, StaffName, EventID FROM Staff")
                staff = cursor.fetchall()

                cursor.execute("SELECT s.Name, z.ZoneName FROM Security s JOIN Zone z ON s.ZoneID = z.ZoneID AND s.VenueID = z.VenueID")
                security_raw = cursor.fetchall()
                security = [{'Name': row['Name'], 'Zone': row['ZoneName']} for row in security_raw]

                cursor.execute("""
                    SELECT 
                        ArtistID, 
                        ArtistName, 
                        GetArtistPerformanceCount(ArtistID) AS performance_count
                    FROM Artists
                """)
                artists = cursor.fetchall()
                
                cursor.execute("SELECT LineupID, EventID, ArtistID, Payment FROM Lineup")
                lineup = cursor.fetchall()
                
                cursor.execute("SELECT VendorID, VendorName, Type FROM Vendors")
                vendors = cursor.fetchall()
                
                cursor.execute("SELECT StallID, StallName, Type, Rental, VendorID FROM Stalls")
                stalls = cursor.fetchall()
                
                response_data = {
                    'users': users,
                    'venues': venues, 
                    'events': events, 
                    'organisers': organisers,
                    'staff': staff, 
                    'security': security, 
                    'tickets': [],
                    'artists': artists,
                    'lineup': lineup,
                    'vendors': vendors,
                    'stalls': stalls
                }
                
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self._send_cors_headers()
                self.end_headers()
                self.wfile.write(json.dumps(response_data, default=json_serial).encode())

            except mysql.connector.Error as err:
                self.send_response(500)
                self.send_header('Content-type', 'application/json')
                self._send_cors_headers()
                self.end_headers()
                self.wfile.write(json.dumps({'error': err.msg}).encode())
            except Exception as e:
                self.send_response(500)
                self.send_header('Content-type', 'application/json')
                self._send_cors_headers()
                self.end_headers()
                self.wfile.write(json.dumps({'error': str(e)}).encode())
            finally:
                if conn.is_connected():
                    cursor.close()
                    conn.close()
        
        # 3. ROUTING FOR /api/analytics (AGGREGATE/NESTED QUERIES)
        elif parsed_path.path == '/api/analytics':
            # This endpoint is for admins. We check the *session role*
            if self.get_user_role() != 'Admin':
                self.send_response(403) # 403 Forbidden
                self.send_header('Content-type', 'application/json')
                self._send_cors_headers()
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Access Denied: Admin role required.'}).encode())
                return
            
            # If we are here, the user is an Admin, so we use the Admin connection
            conn = get_db_connection('Admin')
            if not conn:
                self.send_response(500)
                self.send_header('Content-type', 'application/json')
                self._send_cors_headers()
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Database connection failed'}).encode())
                return
            
            try:
                cursor = conn.cursor(dictionary=True)
                
                # 1. Aggregate Query
                agg_query = """
                    SELECT e.EventName, AVG(t.Price) AS avg_ticket_price
                    FROM Tickets t
                    JOIN Event e ON t.EventID = e.EventID
                    GROUP BY e.EventName
                    ORDER BY avg_ticket_price DESC
                """
                cursor.execute(agg_query)
                avg_prices = cursor.fetchall()
                
                # 2. Nested Query
                nested_query = """
                    SELECT u.FName, u.LName, t.TicketType, t.Price
                    FROM Users u
                    JOIN Tickets t ON u.UserID = t.UserID
                    WHERE t.Price = (
                        SELECT MAX(Price) FROM Tickets
                    )
                """
                cursor.execute(nested_query)
                highest_rollers = cursor.fetchall()
                
                # 3. Join Query
                join_query = """
                    SELECT e.EventName, e.StartTime, o.OrgName
                    FROM Event e
                    JOIN Venue v ON e.VenueID = v.VenueID
                    JOIN Organisers o ON e.OrgID = o.OrgID
                    WHERE v.VenueName = 'Palace Grounds'
                """
                cursor.execute(join_query)
                palace_events = cursor.fetchall()
                
                response_data = {
                    'avg_prices': avg_prices,
                    'highest_rollers': highest_rollers,
                    'palace_events': palace_events
                }
                
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self._send_cors_headers()
                self.end_headers()
                self.wfile.write(json.dumps(response_data, default=json_serial).encode())
                
            except Exception as e:
                self.send_response(500)
                self.send_header('Content-type', 'application/json')
                self._send_cors_headers()
                self.end_headers()
                self.wfile.write(json.dumps({'error': str(e)}).encode())
            finally:
                if conn.is_connected():
                    cursor.close()
                    conn.close()
        
        # 4. FALLBACK
        else:
            self.send_response(404)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(f"Not Found: {parsed_path.path}".encode())

    def do_POST(self):
        """Handler for POST requests."""
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        data = json.loads(post_data)
        
        parsed_path = urlparse(self.path)
        
        # We get the user's role for this session
        current_role = self.get_user_role()
        
        # For login, we need to connect as ADMIN to check the Users table
        if parsed_path.path == '/api/login':
            # We use 'Admin' connection to find the user and get their role
            conn = get_db_connection('Admin') 
            if not conn:
                 self.send_response(500)
                 self.send_header('Content-type', 'application/json')
                 self._send_cors_headers()
                 self.end_headers()
                 self.wfile.write(json.dumps({'error': 'Admin connection failed'}).encode())
                 return
            try:
                cursor = conn.cursor(dictionary=True)
                cursor.execute("SELECT UserID, FName, LName, Role FROM Users WHERE FName = %s", [data['FName']])
                user = cursor.fetchone()
                if user:
                    # === SESSION CREATED ===
                    # We found the user! Store their role for future requests.
                    self.set_user_role(user['Role'])
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self._send_cors_headers()
                    self.end_headers()
                    self.wfile.write(json.dumps(user, default=json_serial).encode())
                else:
                    self.send_response(404) # 404 Not Found
                    self.send_header('Content-type', 'application/json')
                    self._send_cors_headers()
                    self.end_headers()
                    self.wfile.write(json.dumps({'error': 'User not found'}).encode())
                return
            except Exception as e:
                self.send_response(500)
                self.send_header('Content-type', 'application/json')
                self._send_cors_headers()
                self.end_headers()
                self.wfile.write(json.dumps({'error': str(e)}).encode())
            finally:
                if conn.is_connected():
                    cursor.close()
                    conn.close()
        
        
        # For all other POST requests, use the role we stored in the session
        conn = get_db_connection(current_role)
        if not conn:
             self.send_response(500)
             self.send_header('Content-type', 'application/json')
             self._send_cors_headers()
             self.end_headers()
             self.wfile.write(json.dumps({'error': f"Failed to connect as {current_role}"}).encode())
             return
            
        try:
            cursor = conn.cursor(dictionary=True) 
            response_message = {}
            status_code = 200

            if parsed_path.path == '/api/users':
                # This uses the 'general_user' connection, which has INSERT permission
                fname = data['FName']
                lname = data['LName']
                query = "INSERT INTO Users (FName, LName) VALUES (%s, %s)"
                cursor.execute(query, (fname, lname))
                conn.commit()
                new_user_id = cursor.lastrowid
                response_message = {'message': 'User added successfully!', 'UserID': new_user_id, 'FName': fname, 'LName': lname}
                status_code = 201

            elif parsed_path.path == '/api/book_ticket':
                # This uses the 'general_user' connection, which can run BookTicket
                args = [
                    data['UserID'],
                    data['EventID'],
                    data['TicketType'],
                    data['Price'],
                    'Credit Card'
                ]
                cursor.callproc('BookTicket', args)
                conn.commit()
                response_message = {'message': 'Ticket booked successfully!'}
                status_code = 200

            elif parsed_path.path == '/api/cancel_event':
                # If a 'general_user' tries this, the DB will block it!
                # The 'Admin' connection will succeed.
                event_id = data['EventID']
                cursor.callproc('CancelEvent', [event_id])
                conn.commit()
                response_message = {'message': f'Event {event_id} has been cancelled successfully!'}
                status_code = 200
            
            elif parsed_path.path == '/api/add_stall':
                # If a 'general_user' tries this, the DB will block it!
                args = [
                    data['StallName'],
                    data['Type'],
                    data['Rental'],
                    data['VendorID']
                ]
                cursor.callproc('AddStall', args)
                conn.commit()
                response_message = {'message': 'Stall created successfully!'}
                status_code = 201

            elif parsed_path.path == '/api/my_profile':
                # This uses the 'general_user' connection, which has SELECT permission
                user_id = data['UserID']
                
                cursor.execute("SELECT GetUserTotalSpending(%s) AS total_spending", [user_id])
                spending_result = cursor.fetchone()
                
                ticket_query = """
                    SELECT 
                        t.TicketType, t.Price, t.PurchaseDate,
                        e.EventName, e.StartTime, e.Status,
                        v.VenueName, v.City
                    FROM Tickets t
                    JOIN Event e ON t.EventID = e.EventID
                    JOIN Venue v ON e.VenueID = v.VenueID
                    WHERE t.UserID = %s
                    ORDER BY e.StartTime DESC
                """
                cursor.execute(ticket_query, [user_id])
                tickets_result = cursor.fetchall()
                
                nested_query = """
                    SELECT e.EventID, e.EventName, e.StartTime, v.VenueName
                    FROM Event e
                    JOIN Venue v ON e.VenueID = v.VenueID
                    WHERE e.Status = 'Planned' AND e.EventID NOT IN (
                        SELECT EventID FROM Tickets WHERE UserID = %s
                    )
                    ORDER BY e.StartTime
                    LIMIT 5
                """
                cursor.execute(nested_query, [user_id])
                recommended_events = cursor.fetchall()
                
                response_message = {
                    'total_spending': spending_result['total_spending'],
                    'tickets': tickets_result,
                    'recommended_events': recommended_events
                }
                status_code = 200

            else:
                self.send_response(404)
                self.end_headers()
                self.wfile.write(b'Not Found')
                return

            self.send_response(status_code)
            self.send_header('Content-type', 'application/json')
            self._send_cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps(response_message, default=json_serial).encode())

        except mysql.connector.Error as err:
            conn.rollback()
            self.send_response(400)
            self.send_header('Content-type', 'application/json')
            self._send_cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps({'error': err.msg}).encode()) 
        except Exception as e:
            conn.rollback()
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self._send_cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())
        finally:
            if conn.is_connected():
                cursor.close()
                conn.close()

# --- Run the Application ---
if __name__ == '__main__':
    PORT = 5000
    handler_object = MyHttpRequestHandler
    my_server = socketserver.TCPServer(("", PORT), handler_object)
    print(f"Server started at http://localhost:{PORT}")
    my_server.serve_forever()