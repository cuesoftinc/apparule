package service

import (
	"context"
	"io"
	"net/http"
	"strings"
	"testing"
)

type paystackRoundTripper func(*http.Request) (*http.Response, error)

func (f paystackRoundTripper) RoundTrip(r *http.Request) (*http.Response, error) {
	return f(r)
}

func TestPaystackVerificationRequiresSuccessfulAPIResponseAndValidTransaction(t *testing.T) {
	tests := []struct {
		name, body string
		code       int
		wantErr    bool
	}{
		{"success transaction", `{"status":true,"data":{"id":42,"status":"success","reference":"apr_order_1","amount":1000,"currency":"NGN","domain":"test"}}`, 200, false},
		{"failed transaction remains a transaction response", `{"status":true,"data":{"id":42,"status":"failed","reference":"apr_order_1","amount":1000,"currency":"NGN","domain":"test"}}`, 200, false},
		{"API failure", `{"status":false,"message":"not found"}`, 200, true},
		{"HTTP failure", `{"status":false}`, 503, true},
		{"malformed JSON", `{`, 200, true},
		{"missing transaction id", `{"status":true,"data":{"status":"success","reference":"apr_order_1","amount":1000,"currency":"NGN","domain":"test"}}`, 200, true},
		{"missing status", `{"status":true,"data":{"id":42,"reference":"apr_order_1","amount":1000,"currency":"NGN","domain":"test"}}`, 200, true},
		{"zero transaction id", `{"status":true,"data":{"id":0,"status":"success","reference":"apr_order_1","amount":1000,"currency":"NGN","domain":"test"}}`, 200, true},
		{"negative transaction id", `{"status":true,"data":{"id":-42,"status":"success","reference":"apr_order_1","amount":1000,"currency":"NGN","domain":"test"}}`, 200, true},
		{"overflow transaction id", `{"status":true,"data":{"id":9223372036854775808,"status":"success","reference":"apr_order_1","amount":1000,"currency":"NGN","domain":"test"}}`, 200, true},
		{"invalid transaction id", `{"status":true,"data":{"id":"not-an-id","status":"success","reference":"apr_order_1","amount":1000,"currency":"NGN","domain":"test"}}`, 200, true},
		{"missing transaction domain", `{"status":true,"data":{"id":42,"status":"success","reference":"apr_order_1","amount":1000,"currency":"NGN"}}`, 200, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			client := &http.Client{Transport: paystackRoundTripper(func(r *http.Request) (*http.Response, error) {
				if r.Method != http.MethodGet || r.URL.EscapedPath() != "/transaction/verify/apr_order_1" {
					t.Errorf("unexpected request %s %s", r.Method, r.URL.EscapedPath())
				}
				if r.Header.Get("Authorization") != "Bearer sk_test_secret" {
					t.Error("authorization header missing")
				}
				return &http.Response{StatusCode: tt.code, Header: make(http.Header), Body: io.NopCloser(strings.NewReader(tt.body)), Request: r}, nil
			})}
			got, err := requestPaystackVerification(context.Background(), client, "https://api.paystack.test", "sk_test_secret", "apr_order_1")
			if (err != nil) != tt.wantErr {
				t.Fatalf("error = %v, wantErr %v", err, tt.wantErr)
			}
			if !tt.wantErr && (got.Reference != "apr_order_1" || got.ID.String() != "42") {
				t.Fatalf("transaction = %+v", got)
			}
		})
	}
}
