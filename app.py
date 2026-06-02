from flask import Flask, render_template, request, redirect, url_for
import mysql.connector

app = Flask(__name__)

# --- 1. Database Configuration ---
db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': 'your_password',  # <--- Change this to your MySQL password!
    'database': 'public_transport' # <--- Ensure this matches your DB name
}

# --- 2. The Main Dashboard (FETCH ALL DATA) ---
@app.route('/')
def index():
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor(dictionary=True)
        
        # A. Fetch Bookings (From your SQL View)
        cursor.execute("SELECT * FROM BookingSummary")
        bookings = cursor.fetchall()

        # B. Fetch All Passengers
        cursor.execute("SELECT * FROM Passenger")
        passengers = cursor.fetchall()
        
        # C. Fetch Vehicles & Drivers (Joined)
        cursor.execute("""
            SELECT V.VehicleNo, V.Type, V.Model, V.Status, D.Name AS DriverName 
            FROM Vehicle V 
            LEFT JOIN Driver D ON V.DriverID = D.DriverID
        """)
        vehicles = cursor.fetchall()
        
        # D. Fetch All Feedback
        cursor.execute("""
            SELECT P.Name, F.Rating, F.Comments, F.FeedbackDate 
            FROM Feedback F 
            JOIN Passenger P ON F.PassengerID = P.PassengerID
        """)
        feedbacks = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        # Send everything to index.html
        return render_template('index.html', 
                               bookings=bookings, 
                               passengers=passengers, 
                               vehicles=vehicles, 
                               feedbacks=feedbacks)
    except mysql.connector.Error as err:
        return f"<h1>Database Connection Error</h1><p>{err}</p>"

# --- 3. The Booking Logic (CALL PROCEDURE) ---
@app.route('/book', methods=['POST'])
def book_ticket():
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()
    
    # Getting data from the web form
    p_id = request.form['p_id']
    s_id = request.form['s_id']
    seat = request.form['seat']
    fare = request.form['fare']
    
    try:
        # Calls the BookTicket procedure you created in MySQL
        cursor.callproc('BookTicket', [p_id, s_id, seat, fare])
        conn.commit()
    except mysql.connector.Error as err:
        # This catches errors from your Trigger (e.g., Seat already taken)
        return f"<h1>Booking Failed</h1><p>{err.msg}</p><a href='/'>Go Back</a>"
    finally:
        cursor.close()
        conn.close()
        
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(debug=True)