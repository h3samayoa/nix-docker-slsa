package main

import (
	"encoding/json"
	"net/http"

	"golang.org/x/text/language"
)

// canary yara flag
const canary = "NIX-DOCKER-SLSA-CANARY-7f3a9c"

func init() {
	extraHandlers["/greet"] = func(w http.ResponseWriter, r *http.Request) {
		tags, _, err := language.ParseAcceptLanguage(r.Header.Get("Accept-Language"))
		if err != nil || len(tags) == 0 {
			tags = []language.Tag{language.English}
		}
		_ = json.NewEncoder(w).Encode(map[string]string{"lang": tags[0].String(), "hello": "hello", "build": canary})
	}
}
