package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
)

type Note struct {
	NoteId      string `json:"noteId" dynamodbav:"noteId"`
	Description string `json:"description" dynamodbav:"description"`
}

type SecretData struct {
	ClientId     string `json:"client_id"`
	ClientSecret string `json:"client_secret"`
}

func Handler(note Note) (events.APIGatewayProxyResponse, error) {

	headers := map[string]string{"Content-Type": "application/json"}
	n, err := json.Marshal(note)
	if err != nil {
		return events.APIGatewayProxyResponse{
			Body:       "Error parsing request.",
			StatusCode: 400,
			Headers:    headers,
		}, err
	}

	usercreds, err := getSecret(context.TODO())
	if err != nil {
		return events.APIGatewayProxyResponse{
			Body:       "Error parsing request.",
			StatusCode: 400,
			Headers:    headers,
		}, err
	}
	headers["key"] = usercreds.ClientId
	headers["secret"] = usercreds.ClientSecret

	return events.APIGatewayProxyResponse{
		Body:       string(n),
		StatusCode: 200,
		Headers:    headers,
	}, nil
}

func main() {
	lambda.Start(Handler)
}

func getSecret(ctx context.Context) (SecretData, error) {
	secretData := SecretData{}

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		log.Fatalf("unable to load SDK config, %v", err)
	}
	secretsmanagerClient := secretsmanager.NewFromConfig(cfg)

	input := &secretsmanager.GetSecretValueInput{
		SecretId: aws.String("usercreds"),
	}

	result, err := secretsmanagerClient.GetSecretValue(ctx, input)
	if err != nil {
		log.Print(err)
		return secretData, err
	}

	err = json.Unmarshal([]byte(*result.SecretString), &secretData)
	if err != nil {
		return secretData, fmt.Errorf("error parsing item")
	}

	return secretData, nil
}
