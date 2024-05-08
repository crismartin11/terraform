package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go/aws"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
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
	log.Printf("Processing Lambda request %v\n", request.Body)

	// parse request
	note := Note{}
	err := json.Unmarshal([]byte(request.Body), &note)
	if err != nil {
		log.Printf("Error saving note. %v", err)
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
		log.Printf("Error saving note. %v", err)
		return events.APIGatewayProxyResponse{
			Body:       "Error saving note. " + err.Error(),
			StatusCode: 500,
		}, err
	}

	return events.APIGatewayProxyResponse{
		Body:       "Note saved successfully " + note.NoteId + ":" + note.Description,
		StatusCode: 200,
	}, nil
}

func main() {
	lambda.Start(Handler)
}

func save(note Note, credential Credential) error {
	//cfg, err := config.LoadDefaultConfig(context.TODO())
	cfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(credential.Key, credential.Secret, "")),
	)
	if err != nil {
		log.Fatalf("unable to load SDK config, %v", err)
	}
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
