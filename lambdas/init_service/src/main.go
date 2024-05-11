package main

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"

	"github.com/rs/zerolog/log"
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
	logger := log.With().Str("Main", "Handler").Logger()

	headers := map[string]string{"Content-Type": "application/json"}
	n, err := json.Marshal(note)
	if err != nil {
		logger.Error().Msg("Error parsing request.")
		return events.APIGatewayProxyResponse{
			Body:       "Error parsing request.",
			StatusCode: 400,
			Headers:    headers,
		}, err
	}

	usercreds, err := getSecret(context.TODO())
	if err != nil {
		logger.Error().Msg("Error parsing request.")
		return events.APIGatewayProxyResponse{
			Body:       "Error parsing request.",
			StatusCode: 400,
			Headers:    headers,
		}, err
	}
	headers["key"] = usercreds.ClientId
	headers["secret"] = usercreds.ClientSecret

	logger.Info().Msg("Init service finished.")

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
	logger := log.With().Str("method", "getSecret").Logger()

	secretData := SecretData{}

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		logger.Error().Msg("unable to load SDK config." + err.Error())
		return secretData, fmt.Errorf("error unable to load SDK config. %s", err.Error())
	}
	secretsmanagerClient := secretsmanager.NewFromConfig(cfg)

	input := &secretsmanager.GetSecretValueInput{
		SecretId: aws.String("usercreds3"),
	}

	result, err := secretsmanagerClient.GetSecretValue(ctx, input)
	if err != nil {
		logger.Error().Msg("Error getting secrets." + err.Error())
		return secretData, err
	}

	err = json.Unmarshal([]byte(*result.SecretString), &secretData)
	if err != nil {
		return secretData, fmt.Errorf("error parsing item")
	}

	return secretData, nil
}
