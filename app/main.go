package main

import (
	"log"
	"net/http"
	"os"
)

var extraHandlers = map[string]http.HandlerFunc{}

func main() {
	addr := ":8080"
	if v := os.Getenv("ADDR"); v != "" {
		addr = v
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte("ok\n"))
	})
	for path, h := range extraHandlers {
		mux.HandleFunc(path, h)
	}

	log.Printf("app listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
}
