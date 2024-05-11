package main

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go/aws"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"

	"github.com/rs/zerolog/log"
)

type Note struct {
	NoteId      string `json:"noteId" dynamodbav:"noteId"`
	Description string `json:"description" dynamodbav:"description"`
}

type Credential struct {
	Key    string `json:"key"`
	Secret string `json:"secret"`
}

func Handler(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	logger := log.With().Str("Main", "Handler").Logger()

	// parse request
	note := Note{}
	err := json.Unmarshal([]byte(request.Body), &note)
	if err != nil {
		logger.Error().Msg("Error parsing request.")
		return events.APIGatewayProxyResponse{
			Body:       "Error parsing note. " + err.Error(),
			StatusCode: 400,
		}, err
	}

	// Get credentials
	credential := Credential{
		Key:    request.Headers["key"],
		Secret: request.Headers["secret"],
	}

	// Save note
	err = save(note, credential)
	if err != nil {
		logger.Error().Msg("Error parsing request.")
		return events.APIGatewayProxyResponse{
			Body:       "Error saving note. " + err.Error(),
			StatusCode: 500,
		}, err
	}

	logger.Info().Msg("Save service finished.")

	return events.APIGatewayProxyResponse{
		Body:       "Note saved successfully " + note.NoteId + ":" + note.Description,
		StatusCode: 200,
	}, nil
}

func main() {
	lambda.Start(Handler)
}

func save(note Note, credential Credential) error {
	logger := log.With().Str("method", "save").Logger()

	logger.Info().Msg("credential = " + credential.Key + " : " + credential.Secret) // NOTA: solo para darle uso a las credenciales recibidas. Mal exponer en log

	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		logger.Error().Msg("Error parsing request.")
		return fmt.Errorf("error unable to load SDK config. %s", err.Error())
	}

	// cfg, err := config.LoadDefaultConfig(context.TODO(),
	// 	config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(credential.Key, credential.Secret, "")),
	// )
	// if err != nil {
	// 	logger.Error().Msg("Error parsing request.")
	// 	return fmt.Errorf("error unable to load SDK config. %s", err.Error())
	// }

	service := dynamodb.NewFromConfig(cfg)

	// Parse note
	n, err := attributevalue.MarshalMap(note)
	if err != nil {
		return fmt.Errorf("error in parse. %s", err.Error())
	}

	// Save note
	_, err = service.PutItem(context.TODO(), &dynamodb.PutItemInput{
		TableName: aws.String("tf-notes-table"),
		Item:      n,
	})
	if err != nil {
		return fmt.Errorf("error saving note (%s). %s", note.NoteId, err.Error())
	}

	return nil
}
