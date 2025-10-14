# A backend server using only Python's built-in http.server module.
# This version does NOT require Flask to be installed.

import http.server
import socketserver
import json
import mysql.connector
from urllib.parse import urlparse
from datetime import datetime

# --- Configuration ---
# IMPORTANT: Replace with your actual MySQL database credentials
db_config = {
    'user': 'root',
    'password': 'more2134',
    'host': 'localhost',
    'port':3306,
    'database': 'mini_project2'
}

# --- Helper Functions ---
def get_db_connection():
    """Establishes a connection to the database."""
    try:
        conn = mysql.connector.connect(**db_config)
        return conn
    except mysql.connector.Error as err:
        print(f"Error connecting to database: {err}")
        return None

def json_serial(obj):
    """JSON serializer for objects not serializable by default json code"""
    if isinstance(obj, datetime):
        return obj.isoformat()
    raise TypeError ("Type %s not serializable" % type(obj))

# --- Custom Request Handler ---
class MyHttpRequestHandler(http.server.SimpleHTTPRequestHandler):
    
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
        
        # --- ROUTING FOR /api/data ---
        if parsed_path.path == '/api/data':
            conn = get_db_connection()
            if not conn:
                self.send_response(500)
                self.send_header('Content-type', 'application/json')
                self._send_cors_headers()
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Database connection failed'}).encode())
                return

            try:
                cursor = conn.cursor(dictionary=True)
                
                cursor.execute("SELECT UserID, FName, LName FROM Users")
                users = cursor.fetchall()

                cursor.execute("SELECT e.*, v.VenueName, v.City FROM Event e JOIN Venue v ON e.VenueID = v.VenueID")
                events = cursor.fetchall()
                for event in events:
                    event['StartTime'] = json_serial(event['StartTime'])
                    event['EndTime'] = json_serial(event['EndTime'])

                cursor.execute("SELECT OrgID, OrgName FROM Organisers")
                organisers = cursor.fetchall()

                cursor.execute("SELECT StaffID, StaffName, EventID FROM Staff")
                staff = cursor.fetchall()

                cursor.execute("SELECT s.Name, z.ZoneName FROM Security s JOIN Zone z ON s.ZoneID = z.ZoneID AND s.VenueID = z.VenueID")
                security_raw = cursor.fetchall()
                security = [{'Name': row['Name'], 'Zone': row['ZoneName']} for row in security_raw]

                cursor.execute("SELECT TicketID, EventID, UserID, Price FROM Tickets")
                tickets = cursor.fetchall()
                
                response_data = {
                    'users': users, 'events': events, 'organisers': organisers,
                    'staff': staff, 'security': security, 'tickets': tickets
                }
                
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self._send_cors_headers()
                self.end_headers()
                self.wfile.write(json.dumps(response_data).encode())

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
        else:
            # Fallback for any other GET request
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'Not Found')

    def do_POST(self):
        """Handler for POST requests."""
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        data = json.loads(post_data)
        
        parsed_path = urlparse(self.path)
        conn = get_db_connection()
        if not conn:
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self._send_cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps({'error': 'Database connection failed'}).encode())
            return
            
        try:
            cursor = conn.cursor()
            response_message = {}
            status_code = 200

            # --- ROUTING FOR /api/users ---
            if parsed_path.path == '/api/users':
                fname = data['FName']
                lname = data['LName']
                query = "INSERT INTO Users (FName, LName) VALUES (%s, %s)"
                cursor.execute(query, (fname, lname))
                new_user_id = cursor.lastrowid
                response_message = {'message': 'User added successfully!', 'UserID': new_user_id, 'FName': fname, 'LName': lname}
                status_code = 201

            # --- ROUTING FOR /api/book_ticket ---
            elif parsed_path.path == '/api/book_ticket':
                # Manually perform the transaction logic
                ticket_query = "INSERT INTO Tickets (UserID, EventID, TicketType, Price) VALUES (%s, %s, %s, %s)"
                cursor.execute(ticket_query, (data['UserID'], data['EventID'], data['TicketType'], data['Price']))
                new_ticket_id = cursor.lastrowid
                
                trans_query = "INSERT INTO Transactions (TicketID, Amount, PaymentMethod, Status) VALUES (%s, %s, %s, %s)"
                cursor.execute(trans_query, (new_ticket_id, data['Price'], 'Credit Card', 'Completed'))
                
                response_message = {'message': 'Ticket booked successfully!'}
                status_code = 200
            
            else:
                self.send_response(404)
                self.end_headers()
                self.wfile.write(b'Not Found')
                return

            conn.commit()
            self.send_response(status_code)
            self.send_header('Content-type', 'application/json')
            self._send_cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps(response_message).encode())

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



