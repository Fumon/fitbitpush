package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	_ "github.com/lib/pq"
)

func failOnError(err error, msg string) {
	if err != nil {
		log.Fatalf("[X] %s, %s", msg, err)
		panic(fmt.Sprintf("%s, %s", msg, err))
	}
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

type SendDataCommand struct {
	EndDate  string
	FitToken string
	UserID   string
}

type UpdateStatus struct {
	Date  string
	Error string
}

func SendData(token string, weight_decagrams int, date time.Time) (resp *http.Response, body []byte, err error) {
	// Convert decagrams to kilograms
	var w float64 = (float64(weight_decagrams) / 100.0)
	// Build body
	data := url.Values{}
	data.Set("weight", strconv.FormatFloat(w, 'f', 2, 64))
	data.Set("date", date.Format("2006-01-02"))

	strings.NewReader(data.Encode())

	// Create request
	req, err := http.NewRequest(
		"POST",
		"https://api.fitbit.com/1/user/-/body/log/weight.json",
		strings.NewReader(data.Encode()),
	)
	if err != nil {
		return nil, nil, err
	}

	// Set Headers
	req.Header.Set("Authorization", fmt.Sprint("Bearer ", token))
	req.Header.Add("Content-Type", "application/x-www-form-urlencoded")

	// Client
	client := &http.Client{}

	resp, err = client.Do(req)

	// Read the body
	body, _ = ioutil.ReadAll(resp.Body)
	resp.Body.Close()

	// Return
	return
}

func main() {
	servport := os.Getenv("PORT")
	if servport == "" {
		servport = ":8989"
	} else if servport == "3000" {
		servport = ":3000"
	}

	log.Println("[i] Server started")

	// Connect to DB
	db, err := sql.Open("postgres", "user=appread dbname='quantifiedSelf' sslmode=disable")
	failOnError(err, "Error connecting to database")
	defer db.Close()

	// Restful handler
	r := mux.NewRouter()
	r.HandleFunc("/getWeightDates", func(w http.ResponseWriter, r *http.Request) {

	})

	// Terrible, no parsing of inputs... whatever. Single use page.
	r.HandleFunc("/getWeights/{endDate}", func(w http.ResponseWriter, r *http.Request) {
		// Grab vars
		vars := mux.Vars(r)

		var output sql.NullString
		query := `SELECT json_object_agg(w.date, w.weight) FROM (SELECT to_char(date, 'YYYY-MM-DD') as date, MIN(weight) as weight FROM (SELECT date_trunc('day', date) as date, weight FROM aleph.weight WHERE date < to_timestamp($1, 'MM-DD-YYYY')) r GROUP BY date ORDER BY date DESC) w;`
		err := db.QueryRow(query, vars["endDate"]).Scan(&output)
		if err != nil {
			log.Println("Error retriving from DB, ", err)
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(w, "Error retriving from DB, ", err)
		}

		// Print out returned
		w.Header().Set("Content-Type", "application/json")
		if output.Valid {
			fmt.Fprint(w, output.String)
		} else {
			fmt.Fprint(w, "[]")
		}
	})

	r.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		ws, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			log.Println(err)
			return
		}

		defer ws.Close()

		// SPAGHETTI!!!
		log.Println("Websocket connected, waiting for command...")
		// Get the key we need to send to fitbit
		var command SendDataCommand
		err = ws.ReadJSON(&command)
		if err != nil {
			log.Println("Error with Websocket, ", err)
			return
		}

		// Don't care what the client wants
		go func() {
			for {
				if _, _, err := ws.NextReader(); err != nil {
					ws.Close()
					break
				}
			}
		}()

		// Grab the data we're going to send

		query := `SELECT date, MIN(weight) as weight FROM (SELECT date_trunc('day', date) as date, weight FROM aleph.weight WHERE date < to_timestamp($1, 'MM-DD-YYYY')) r GROUP BY date ORDER BY date DESC;`
		rows, err := db.Query(query, command.EndDate)
		if err != nil {
			log.Println("Error retriving from DB, ", err)
			// Maybe write to the client? I don't know. Close seems sufficient.
		}
		defer rows.Close()
		log.Println("Sending data for UID: ", command.UserID, " with bearer token: ", command.FitToken)
		for rows.Next() {
			var date time.Time
			var weight int
			if err := rows.Scan(&date, &weight); err != nil {
				log.Println("Error getting results from rows, ", err)
				break
			}
			// Send the data to fitbit
			log.Println("SendData: {", date, ", ", weight, "}")

			resp, body, err := SendData(command.FitToken, weight, date)
			if resp.StatusCode != 201 || err != nil {
				var b interface{}
				json.Unmarshal(body, &b)
				log.Printf("Response:\n\t Resp: %+v\n\tBody: %+v\n\tError: %+v\n", resp, b, err)

				// Depending on success, send info to page
				v := UpdateStatus{Date: date.Format("2006-01-02"), Error: fmt.Sprint("E: ", resp.StatusCode)}
				ws.WriteJSON(v)
				break
			} else {
				v := UpdateStatus{Date: date.Format("2006-01-02"), Error: "Done!"}
				ws.WriteJSON(v)
			}
		}
	})

	r.PathPrefix("/").Handler(http.FileServer(http.Dir("ui")))

	http.Handle("/", r)
	log.Println("[i] Serving on ", servport, "\n\tWaiting...")

	log.Fatal(http.ListenAndServe(servport, nil))
	// <-killchan

	log.Println("[i] Shutting down...")
}
