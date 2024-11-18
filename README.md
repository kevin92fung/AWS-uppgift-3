# AWS Uppgift 3

Denna CloudFormation-mall provisionerar en **serverlös miljö** för ett kontaktformulär som skickar **bekräftelsemail** till den ansvarige personen.

Webbplatsen är hostad på en **S3-bucket** och nås av användare genom **CloudFront**.

Lösningen använder flera **Lambda-funktioner** för backend-bearbetning, med **GitHub-integration** och **CodePipeline** för att hantera uppdateringar av webbplatsen.

## Förutsättningar

För att kunna genomföra detta projekt behöver du:

- Ett konto på [AWS](https://aws.amazon.com/) för att använda tjänster som Lambda, S3, DynamoDB, och CodePipeline.
- Ett konto på [GitHub](https://github.com/) för att hantera kodversionering och automatiserad deployment.
- Två e-postadresser: en för att skicka bekräftelsemail och en för den ansvarige att ta emot meddelanden via SES.
- [Visual Studio Code (VSCode)](https://code.visualstudio.com/) rekommenderas för att redigera och utveckla projektet, med stöd för olika AWS- och GitHub-verktyg.
- **AWS CLI**: Installera och konfigurera [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) för att interagera med AWS-tjänster direkt från terminalen.








## Innehållsförteckning

1. [**Steg 1**: Skapa GitHub Repository](#steg-1-skapa-github-repository)
2. [**Steg 2**: Skapa `.env`-fil](#steg-2-skapa-env-fil)
3. [**Steg 3**: Skapa CloudFormation-mall](#steg-3-skapa-cloudformation-mall)
4. [**Steg 4**: Skapa Deploy-skript](#steg-4-skapa-deploy-skript)
5. [**Steg 5**: Lägg till DynamoDB-tabell i `cloudformation.yaml`](#steg-5-lägg-till-dynamodb-tabell-i-cloudformationyaml)
6. [**Steg 6**: Lägg till IAM-roller i cloudformation.yaml](#steg-6-lägg-till-iam-roller-i-cloudformationyaml)
7. [**Steg 7**: Lägg till e-post för SES](#steg-7-lägg-till-e-post-för-ses)
8. [**Steg 8**: Lägg till Lambda-funktion för att bearbeta kontaktformulär](#steg-8-lägg-till-lambda-funktion-för-att-bearbeta-kontaktformulär)
9. [**Steg 9**: Lägg till trigger för Lambda-funktion via API Gateway](#steg-9-lägg-till-trigger-för-lambda-funktion-via-api-gateway)
10. [**Steg 10**: Lägg till Lambda-funktion för att skicka e-postmeddelande med kontaktinformation](#steg-10-lägg-till-lambda-funktion-för-att-skicka-e-postmeddelande-med-kontaktinformation)
11. [**Steg 11**: Lägg till trigger för SES-funktionen](#steg-11-lägg-till-trigger-för-ses-funktionen)
12. [**Steg 12**: Lägg till S3 Bucket för att lagra webbplatsens filer](#steg-12-lägg-till-s3-bucket-för-att-lagra-webbplatsens-filer)
13. [**Steg 13**: Lägg till CloudFront Distribution framför S3-bucket](#steg-13-lägg-till-cloudfront-distribution-framför-s3-bucket)
14. [**Steg 14**: Lägg till rättigheter för S3-bucket](#steg-14-lägg-till-rättigheter-för-s3-bucket)
15. [**Steg 15**: Lägg till IAM-roll för Lambda att ladda upp till S3-bucket](#steg-15-lägg-till-iam-roll-för-lambda-att-ladda-upp-till-s3-bucket)
16. [**Steg 16**: Lägg till Lambda-funktion för att ladda upp `index.html` till S3-bucket vid deploy](#steg-16-lägg-till-lambda-funktion-för-att-ladda-upp-indexhtml-till-s3-bucket-vid-deploy)
17. [**Steg 17**: Lägg till S3-bucket för CodePipeline artefakter](#steg-17-lägg-till-s3-bucket-för-codepipeline-artefakter)
18. [**Steg 18**: Lägg till IAM Roll för Lambda och CodePipeline](#steg-18-lägg-till-iam-roll-för-lambda-och-codepipeline)
19. [**Steg 19**: Lägg till Lambda Funktion för CloudFront Invalidering](#steg-19-lägg-till-lambda-funktion-för-cloudfront-invalidering)
20. [**Steg 20**: Lägg till CodePipeline](#steg-20-lägg-till-codepipeline)
21. [**Steg 21**: Slutför autentisering av GitHub Connect via AWS Console](#steg-21-slutför-autentisering-av-github-connect-via-aws-console)
22. [**Steg 22**: Ladda upp index.html till GitHub Repository från S3](#steg-22-ladda-upp-indexhtml-till-github-repository-från-s3)
23. [**Steg 23**: Pusha en förändring av `index.html`, verifiera att pipeline kör och testa CloudFront invalidation](#steg-23-pusha-en-förändring-av-indexhtml-verifiera-att-pipeline-kör-och-testa-cloudfront-invalidation)
24. [**Steg 24**: Rensa upp och ta bort CloudFormation-resurser](#steg-24-rensa-upp-och-ta-bort-cloudformation-resurser)








## Steg 1: Skapa GitHub Repository
1. Gå till [GitHub](https://github.com/) och logga in.
2. Klicka på knappen **New** i övre högra hörnet för att skapa ett nytt repository.
3. Ge repositoryt ett namn (t.ex. `aws-contact-form`) och välj om det ska vara publikt eller privat.
4. Klicka på **Create repository** för att slutföra.

[⬆️ Till toppen](#top)










## Steg 2: Skapa `.env`-fil
1. Öppna terminalen och kör följande kommandon för att skapa en `.env`-fil:

```bash
touch .env
```

2. Lägg sedan till följande innehåll i `.env`-filen, där du ersätter platshållarna `<mail@example.com>`, `<mail@example2.com>`, och `<username/repository>` med dina faktiska värden:

```env
# Email Configuration Parameters
FROM_EMAIL=<mail@example.com>
TO_EMAIL=<mail@example2.com>

# GitHub Repository ID
GITHUB_REPOSITORY_ID=<username/repository>
```

[⬆️ Till toppen](#top)








## Steg 3: Skapa CloudFormation-mall
1. Skapa en ny fil för CloudFormation-mallen:

```bash
touch cloudformation.yaml
```

2. Lägg till följande innehåll i `cloudformation.yaml`:

```yaml
AWSTemplateFormatVersion: 2010-09-09
Description: |
  Denna CloudFormation-mall provisionerar en serverlös miljö för ett kontaktformulär som skickar bekräftelsemail till den ansvarige personen.
  Webbplatsen är hostad på en S3-bucket och nås av användare genom CloudFront.
  Lösningen använder flera Lambda-funktioner för backend-bearbetning, med GitHub-integration och CodePipeline för att hantera uppdateringar av webbplatsen.

Resources:
  # Här kommer dina AWS-resurser att definieras, exempelvis S3-bucket, Lambda, API Gateway, osv.
```

[⬆️ Till toppen](#top)











## Steg 4: Skapa Deploy-skript
1. Skapa en ny fil för deploy-skriptet:

```bash
touch deploy.sh
```

2. Lägg till följande innehåll i `deploy.sh`-filen:

```bash
#!/bin/bash

# Ladda miljövariabler från .env-filen
source .env

# Sätt variabler för template-filen och stacknamnet
TEMPLATE_FILE="cloudformation.yaml"  # Ändra detta till sökvägen till din CloudFormation-mallfil
STACK_NAME="serverless"  # Ändra detta till ditt stacknamn

# Deploya CloudFormation-stack med de laddade miljövariablerna
aws cloudformation deploy \
  --template-file "$TEMPLATE_FILE" \
  --stack-name "$STACK_NAME"
```

3. Kör skriptet för att deploya CloudFormation-stack:

```bash
./deploy.sh
```

[⬆️ Till toppen](#top)









## Steg 5: Lägg till DynamoDB-tabell i `cloudformation.yaml`

I det här steget lägger vi till en DynamoDB-tabell som kommer att användas för att lagra kontaktinformation. Tabellen kommer att ha en partition key baserad på `timestamp` och strömmar som fångar både gamla och nya bilder av data.

### 1. Lägg till följande i `cloudformation.yaml`:

```yaml
Resources:
  # DynamoDB Table
  AddContactsTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: Contacts
      AttributeDefinitions:
        - AttributeName: timestamp
          AttributeType: S
      KeySchema:
        - AttributeName: timestamp
          KeyType: HASH
      ProvisionedThroughput:
        ReadCapacityUnits: 5
        WriteCapacityUnits: 5
      StreamSpecification:
        StreamViewType: NEW_AND_OLD_IMAGES
```

### Beskrivning:
- **AddContactsTable**: Skapar en DynamoDB-tabell med namnet `Contacts`. Den använder `timestamp` som partition key (HASH key) och definierar en ström som fångar både nya och gamla bilder av data.
- **AttributeDefinitions**: Definierar attributet `timestamp`, som används som partition key.
- **KeySchema**: Anger att `timestamp` är partition key.
- **ProvisionedThroughput**: Sätter läs- och skrivkapacitet för tabellen till 5 enheter vardera. Detta kan ändras beroende på belastningen på applikationen.
- **StreamSpecification**: Aktiverar DynamoDB-strömmar med både gamla och nya bilder av data, vilket gör att förändringar i tabellen kan fångas för vidare bearbetning eller spårning.

### 2. Kör deploy-skriptet:

Efter att ha uppdaterat `cloudformation.yaml`, kör deploy-skriptet:

```bash
./deploy.sh
```

### 3. Verifiera i AWS Console:
1. Gå till **DynamoDB** under **Services**.
2. Klicka på **Tables**.
3. Verifiera att tabellen `Contacts` finns och att den har rätt inställningar, med `timestamp` som partition key och strömmar aktiverade för att fånga både gamla och nya bilder av data.

[⬆️ Till toppen](#top)












## Steg 6: Lägg till IAM-roller i cloudformation.yaml

I det här steget lägger vi till IAM-roller som Lambda-funktioner behöver för att få åtkomst till SES och DynamoDB.

Lägg till följande kod i din `cloudformation.yaml` efter de tidigare definierade resurserna:

```yaml
Resources:
  # Tidigare definierade resurser...

  # Skapa IAM-rollen för Lambda att få åtkomst till SES
  LambdaRoleToAccessSES:
    Type: AWS::IAM::Role
    Properties:
      RoleName: LambdaRoleToAccessSES
      Description: Rolle för Lambda att få åtkomst till SES med grundläggande exekvering och full åtkomst till DynamoDB
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: sts:AssumeRole
      Policies:
        - PolicyName: LambdaFullDynamoDBAccess
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - dynamodb:PutItem
                  - dynamodb:UpdateItem
                  - dynamodb:BatchWriteItem
                  - dynamodb:Query
                  - dynamodb:Scan
                  - dynamodb:GetItem
                  - dynamodb:DescribeStream  # Lägg till behörigheter för att beskriva strömmen
                  - dynamodb:GetRecords  # Lägg till behörigheter för att läsa poster från strömmen
                  - dynamodb:GetShardIterator  # Lägg till behörigheter för att hämta shard-iterators
                  - dynamodb:ListStreams  # Lägg till behörigheter för att lista strömmar
                Resource: "*"
        - PolicyName: AWSLambdaBasicExecutionRole
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - logs:CreateLogGroup
                  - logs:CreateLogStream
                  - logs:PutLogEvents
                Resource: arn:aws:logs:your-region:your-account-id:log-group:/aws/lambda/*
        - PolicyName: AmazonSESFullAccess
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - ses:*
                Resource: "*"

  # Skapa IAM-rollen för Lambda att få åtkomst till DynamoDB
  LambdaRoleToAccessDynamoDB:
    Type: AWS::IAM::Role
    Properties:
      RoleName: LambdaRoleToAccessDynamoDB
      Description: Rolle för Lambda att få åtkomst till DynamoDB med grundläggande exekvering och full åtkomst till DynamoDB
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: sts:AssumeRole
      Policies:
        - PolicyName: LambdaFullDynamoDBAccess
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - dynamodb:PutItem
                  - dynamodb:UpdateItem
                  - dynamodb:BatchWriteItem
                  - dynamodb:Query
                  - dynamodb:Scan
                  - dynamodb:GetItem
                Resource: !GetAtt AddContactsTable.Arn
        - PolicyName: AWSLambdaBasicExecutionRole
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - logs:CreateLogGroup
                  - logs:CreateLogStream
                  - logs:PutLogEvents
                Resource: arn:aws:logs:your-region:your-account-id:log-group:/aws/lambda/*
```

### Beskrivning:
- **LambdaRoleToAccessSES**: Skapar en IAM-roll som tillåter Lambda att komma åt SES och DynamoDB för att hantera e-postsändningar och data.
- **LambdaRoleToAccessDynamoDB**: Skapar en IAM-roll för Lambda som ger åtkomst till DynamoDB-tabellen Contacts för att spara kontaktinformation.

### Kör:
1. Lägg till koden i din `cloudformation.yaml`.
2. Uppdatera och spara ditt `deploy.sh`-skript.

### Uppdatera deploy-skriptet:

```bash
#!/bin/bash

# Load environment variables from the .env file
source .env

# Set variables for the template file and stack name
TEMPLATE_FILE="CloudFormation.yaml"  # Change this to the path of your CloudFormation template file
STACK_NAME="uppgift3"  # Change this to your stack name

# Deploy the CloudFormation stack using the loaded environment variables
aws cloudformation deploy \
  --template-file "$TEMPLATE_FILE" \
  --stack-name "$STACK_NAME" \
  --capabilities CAPABILITY_NAMED_IAM
```

### Kör:
1. Kör deploy-skriptet:

```bash
./deploy.sh
```

### Verifiera:
1. Gå till **AWS Console**.
2. Navigera till **IAM** under **Services**.
3. Klicka på **Roles** och verifiera att rollerna **LambdaRoleToAccessSES** och **LambdaRoleToAccessDynamoDB** finns och har rätt policyer tilldelade.

[⬆️ Till toppen](#top)













## Steg 7: Lägg till e-post för SES

I det här steget skapar vi e-postidentiteter i Amazon SES (Simple Email Service) för att kunna använda dem som avsändaradress och mottagaradress för e-postmeddelanden som skickas via SES. Dessa e-postidentiteter måste verifieras innan de kan användas för att skicka e-post.

### Lägg till följande i din `cloudformation.yaml`:

```yaml
Resources:
  # Tidigare definierade resurser...

  # EmailIdentity for the From Email
  MyEmailIdentity1:
    Type: AWS::SES::EmailIdentity
    Properties:
      EmailIdentity: !Ref FromEmail

  # EmailIdentity for the To Email
  MyEmailIdentity2:
    Type: AWS::SES::EmailIdentity
    Properties:
      EmailIdentity: !Ref ToEmail
```

### Beskrivning:
- **MyEmailIdentity1**: Skapar en e-postidentitet för avsändaradressen som definieras av parameter `FromEmail`. Detta gör att e-postmeddelanden kan skickas från denna adress via SES.
- **MyEmailIdentity2**: Skapar en e-postidentitet för mottagaradressen som definieras av parameter `ToEmail`. Denna e-postadress används för att ta emot e-postmeddelanden från SES.

Innan dessa e-postadresser kan användas för att skicka e-post, måste de verifieras genom att en verifieringslänk skickas till varje e-postadress. Du kommer att behöva klicka på länken för att bekräfta ägarskapet av adresserna.

### Uppdatera deploy-skriptet:

För att kunna använda parametrarna för e-postadresserna när du kör CloudFormation, uppdatera ditt deploy-skript:

```bash
#!/bin/bash

# Load environment variables from the .env file
source .env

# Set variables for the template file and stack name
TEMPLATE_FILE="CloudFormation.yaml"  # Change this to the path of your CloudFormation template file
STACK_NAME="uppgift3"  # Change this to your stack name

# Deploy the CloudFormation stack using the loaded environment variables
aws cloudformation deploy \
  --template-file "$TEMPLATE_FILE" \
  --stack-name "$STACK_NAME" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    FromEmail="$FROM_EMAIL" \
    ToEmail="$TO_EMAIL"
```

### Kör:
1. Lägg till koden i din `cloudformation.yaml`.
2. Uppdatera och spara ditt `deploy.sh`-skript.
3. Kör deploy-skriptet:

```bash
./deploy.sh
```

### Verifiera:
1. Gå till **AWS Console**.
2. Navigera till **SES** under **Services**.
3. Verifiera att e-postidentiteterna **MyEmailIdentity1** och **MyEmailIdentity2** finns under SES e-postidentiteter.
4. För varje e-postidentitet, kontrollera om det skickats en verifieringslänk.
5. Klicka på verifieringslänken som skickas till e-postadressen för att slutföra verifieringen och aktivera e-postadressen för användning i SES.

Efter verifiering kommer du kunna skicka och ta emot e-post via SES med de angivna e-postadresserna.

[⬆️ Till toppen](#top)









## Steg 8: Lägg till Lambda-funktion för att bearbeta kontaktformulär

I det här steget kommer vi att skapa en Lambda-funktion som tar emot data från kontaktformuläret via API Gateway och sparar denna information i DynamoDB-tabellen.

### Lägg till kod i `cloudformation.yaml`:

```yaml
Resources:
  # Tidigare definierade resurser...

  # Lambda function to process the contact form submission
  AddContactInfoFunction:
    Type: AWS::Lambda::Function
    DependsOn:
      - LambdaRoleToAccessDynamoDB
      - AddContactsTable
    Properties:
      FunctionName: AddContactInfo
      Runtime: python3.12
      Role: !GetAtt LambdaRoleToAccessDynamoDB.Arn
      Handler: index.lambda_handler
      Code:
        ZipFile: |
          import json
          import boto3
          from datetime import datetime

          def lambda_handler(event, context):
            db = boto3.resource('dynamodb')
            table = db.Table('Contacts')

            dateTime = (datetime.now()).strftime("%Y-%m-%d %H:%M:%S")

            try:
                payload = json.loads(event['body'])

                table.put_item(
                  Item={
                    'timestamp': dateTime,
                    'name': payload['name'],
                    'email': payload['email'],
                    'message': payload['msg']
                  }
                )

                return {
                    'statusCode': 200,
                    'body': json.dumps('Successfully saved contact info!'),
                    'headers': {
                        "Access-Control-Allow-Origin": "*",
                        "Access-Control-Allow-Credentials": True,
                    }
                }

            except Exception as e:
                return {
                    'statusCode': 400,
                    'body': json.dumps(f'Error saving contact info: {str(e)}'),
                    'headers': {
                        "Access-Control-Allow-Origin": "*",
                        "Access-Control-Allow-Credentials": True,
                    }
                }
      Environment:
        Variables:
          TABLE_NAME: !Ref AddContactsTable
```

### Förklaring:

- **Lambda-funktionen**: Den här funktionen får JSON-data via API Gateway, parsar den och sparar informationen (namn, e-post och meddelande) i DynamoDB-tabellen `Contacts`.
- **Boto3 och DynamoDB**: `boto3` används för att interagera med DynamoDB. Den hämtar den angivna tabellen och lägger till ett nytt objekt med den information som skickades i formuläret.
- **Error Handling**: Funktionen har grundläggande felhantering som returnerar ett felmeddelande om något går fel.

### Kör:

1. Lägg till koden i din `cloudformation.yaml`-fil.
2. Kör deploy-skriptet:

   ```bash
   ./deploy.sh
   ```

### Verifiera:

1. Gå till **AWS Console** och navigera till **Lambda**.
2. Kontrollera att Lambda-funktionen **AddContactInfo** har skapats.
3. Kontrollera att miljövariabeln `TABLE_NAME` är korrekt inställd på DynamoDB-tabellen `Contacts`.
4. Gå till **API Gateway** och välj den API som skapades (t.ex. `ContactsAPI`).
5. Klicka på fliken **Test**.
6. Välj **POST** som metod och använd följande JSON som request body:

```json
{
  "name": "test", 
  "email": "test@email.com", 
  "msg": "testar så funktionen fungerar"
}
```

7. Klicka på **Test** för att skicka förfrågan.

8. Gå till **DynamoDB** i AWS Console och kontrollera att den nya posten har lagts till i tabellen **Contacts** med rätt `name`, `email` och `message`.

[⬆️ Till toppen](#top)










## Steg 9: Lägg till trigger för Lambda-funktion via API Gateway

I det här steget kommer vi att skapa en API Gateway som fungerar som en trigger för Lambda-funktionen, vilket gör att vi kan skicka förfrågningar till Lambda-funktionen via HTTP POST. API Gateway kommer att vidarebefordra dessa förfrågningar till Lambda-funktionen, som sedan kommer att spara kontaktinformationen i DynamoDB.

### Lägg till kod i `cloudformation.yaml`:

```yaml
Resources:
  # Tidigare definierade resurser...

  # API Gateway to integrate with Lambda function
  ApiGatewayRestApi:
    Type: AWS::ApiGateway::RestApi
    Properties:
      Name: "ContactsAPI"
      Description: "API Gateway for AddContactInfo Lambda integration"
      EndpointConfiguration:
        Types:
          - REGIONAL

  ApiGatewayResourceAddContactInfo:
    Type: AWS::ApiGateway::Resource
    Properties:
      ParentId: !GetAtt ApiGatewayRestApi.RootResourceId
      PathPart: "AddContactInfo"
      RestApiId: !Ref ApiGatewayRestApi

  ApiGatewayMethodAny:
    Type: AWS::ApiGateway::Method
    DependsOn:
      - AddContactInfoFunction
      - ApiGatewayResourceAddContactInfo
    Properties:
      RestApiId: !Ref ApiGatewayRestApi
      ResourceId: !Ref ApiGatewayResourceAddContactInfo
      HttpMethod: ANY
      AuthorizationType: NONE
      Integration:
        IntegrationHttpMethod: POST
        Type: AWS_PROXY
        Uri: !Sub arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${AddContactInfoFunction.Arn}/invocations
      MethodResponses:
        - StatusCode: '200'

  ApiGatewayMethodOPTIONS:
    Type: AWS::ApiGateway::Method
    DependsOn:
      - ApiGatewayMethodAny
    Properties:
      RestApiId: !Ref ApiGatewayRestApi
      ResourceId: !Ref ApiGatewayResourceAddContactInfo
      HttpMethod: OPTIONS
      AuthorizationType: NONE
      MethodResponses:
        - StatusCode: '200'
          ResponseParameters:
            method.response.header.Access-Control-Allow-Headers: "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
            method.response.header.Access-Control-Allow-Methods: "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
            method.response.header.Access-Control-Allow-Origin: "'*'"
          ResponseModels:
            application/json: "Empty"
      Integration:
        Type: MOCK
        IntegrationResponses:
          - StatusCode: '200'
            ResponseParameters:
              method.response.header.Access-Control-Allow-Headers: "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
              method.response.header.Access-Control-Allow-Methods: "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
              method.response.header.Access-Control-Allow-Origin: "'*'"
        RequestTemplates:
          application/json: '{"statusCode": 200}'

  # Lambda Permission to allow API Gateway to invoke the Function
  LambdaInvokePermission:
    Type: AWS::Lambda::Permission
    Properties:
      Action: lambda:InvokeFunction
      FunctionName: !Ref AddContactInfoFunction
      Principal: apigateway.amazonaws.com
      SourceArn: !Sub arn:aws:execute-api:${AWS::Region}:${AWS::AccountId}:${ApiGatewayRestApi}/*/*/AddContactInfo

  # API Gateway Deployment
  ApiGatewayDeployment:
    Type: AWS::ApiGateway::Deployment
    DependsOn:
      - ApiGatewayMethodAny
    Properties:
      RestApiId: !Ref ApiGatewayRestApi
      StageName: default
```

### Kör:

1. Lägg till koden i din `cloudformation.yaml`-fil.
2. Kör deploy-skriptet:

   ```bash
   ./deploy.sh
   ```

### Verifiera:

1. **Gå till AWS Console** och navigera till **API Gateway**.
2. Under **API Gateway**, välj din nya API **ContactsAPI**.
3. Gå till **Resources** och välj resursen **/AddContactInfo**.
4. Klicka på **Test** i det högra fönstret.
5. Välj **POST** som metod.
6. I **Request Body**, lägg till följande JSON:

   ```json
   {
     "name": "test2", 
     "email": "test2@email.com", 
     "msg": "testar om api fungerar"
   }
   ```

7. Klicka på **Test** för att skicka förfrågan till API Gateway.
8. Kontrollera **Response Body** för att säkerställa att du får en framgångsrik statuskod (200 OK) och att API:t svarar med ett meddelande om att informationen har sparats korrekt.
9. Gå till **DynamoDB** och öppna tabellen **Contacts**.
10. Verifiera att ett nytt objekt har lagts till med de värden du skickade i POST-förfrågan: `name`, `email`, `message`, samt en `timestamp`.

[⬆️ Till toppen](#top)








## Steg 10: Lägg till Lambda-funktion för att skicka e-postmeddelande med kontaktinformation

I det här steget kommer vi att skapa en Lambda-funktion som hämtar kontaktinformation från DynamoDB och skickar ett e-postmeddelande via SES (Simple Email Service) med informationen.

### Lägg till kod i `cloudformation.yaml`:

```yaml
Resources:
  # Tidigare definierade resurser...

  # SendContactInfoEmail Function
  SendContactInfoEmailFunction:
    Type: AWS::Lambda::Function
    DependsOn:
      - LambdaRoleToAccessSES
      - AddContactsTable
      - MyEmailIdentity1
      - MyEmailIdentity2
    Properties:
      FunctionName: SendContactInfoEmail
      Runtime: python3.12
      Role: !GetAtt LambdaRoleToAccessSES.Arn
      Handler: index.lambda_handler
      Environment:
        Variables:
          TABLE_NAME: !Ref AddContactsTable  # Reference DynamoDB table from CloudFormation
          FROM_EMAIL: !Ref MyEmailIdentity1  # Reference the verified sender email identity
          TO_EMAIL: !Ref MyEmailIdentity2  # Reference the recipient email identity
      Code:
        ZipFile: |
          import json
          import boto3
          import os
          from datetime import datetime

          # Initialize the DynamoDB client
          dynamodb = boto3.resource('dynamodb')
          table = dynamodb.Table(os.environ['TABLE_NAME'])  # Get the table name from environment variable

          def lambda_handler(event, context):
              # Scan the DynamoDB table
              result = table.scan()
              items = result['Items']

              # Sort the items by timestamp in descending order
              # Ensure 'timestamp' is parsed into a datetime object for proper comparison
              items.sort(key=lambda x: datetime.strptime(x['timestamp'], '%Y-%m-%d %H:%M:%S'), reverse=True)

              # Initialize SES client (uses Lambda's region by default)
              ses = boto3.client('ses')

              # Build the HTML table body for the email
              body = """
              <html>
              <head></head>
              <body>
              <h3>Contact Information</h3>
              <table border="1">
                  <tr>
                      <th>Name</th>
                      <th>Email</th>
                      <th>Message</th>
                      <th>Timestamp</th>
                  </tr>
              """
              
              # Loop through the items and create table rows
              for item in items:
                  body += f"""
                  <tr>
                      <td>{item['name']}</td>
                      <td>{item['email']}</td>
                      <td>{item['message']}</td>
                      <td>{item['timestamp']}</td>
                  </tr>
                  """
              
              # Closing HTML tags
              body += """
              </table>
              </body>
              </html>
              """

              # Send email using SES
              ses.send_email(
                  Source=os.environ['FROM_EMAIL'],  # Reference the environment variable for the sender email
                  Destination={ 
                      'ToAddresses': [
                          os.environ['TO_EMAIL']  # Reference the environment variable for the recipient email
                      ]
                  },
                  Message={
                      'Subject': {
                          'Data': 'Contact Info Notification',
                          'Charset': 'UTF-8'
                      },
                      'Body': {
                          'Html': {  # Specify that we're sending HTML content
                              'Data': body,
                              'Charset': 'UTF-8'
                          }
                      }
                  }
              )

              return {
                  'statusCode': 200,
                  'body': json.dumps('Successfully sent email from Lambda using Amazon SES')
              }
```

### Förklaring:

- **Lambda-funktionen**: Den här funktionen hämtar kontaktinformation från DynamoDB, sorterar den efter timestamp och skickar informationen i ett HTML-formaterat e-postmeddelande via SES.
- **DynamoDB och SES**: Funktionen använder DynamoDB för att hämta kontaktuppgifter och SES för att skicka e-postmeddelandet.
- **Miljövariabler**: `TABLE_NAME` refererar till DynamoDB-tabellen som lagrar kontaktuppgifterna. `FROM_EMAIL` och `TO_EMAIL` är e-postadresser som refereras till via verifierade e-postidentiteter i SES.

### Kör:

1. Lägg till koden i din `cloudformation.yaml`-fil.
2. Kör deploy-skriptet:

   ```bash
   ./deploy.sh
   ```

### Verifiera:

1. Gå till **AWS Console** och navigera till **Lambda**.
2. Kontrollera att Lambda-funktionen **SendContactInfoEmail** har skapats.
3. Kontrollera att miljövariablerna `TABLE_NAME`, `FROM_EMAIL` och `TO_EMAIL` är korrekt inställda.
4. Testa funktionen genom att manuellt utlösa den i Lambda-konsolen eller genom att skicka en begäran till API Gateway som triggar Lambda-funktionen. Kontrollera att e-postmeddelandet skickas till den angivna mottagaren och att det innehåller kontaktinformationen från DynamoDB.

[⬆️ Till toppen](#top)









## Steg 11: Lägg till trigger för SES-funktionen

I det här steget kommer vi att lägga till en trigger för Lambda-funktionen som skickar e-postmeddelanden via SES. Triggern kommer att vara en DynamoDB Stream som aktiverar funktionen varje gång det läggs till en ny post i DynamoDB-tabellen.

### Lägg till kod i `cloudformation.yaml`:

```yaml
Resources:
  # Tidigare definierade resurser...

  # Enable SendContactInfoEmailFunction to be triggered by DynamoDB stream
  SendContactInfoEmailFunctionDynamoDBTrigger:
    Type: AWS::Lambda::EventSourceMapping
    DependsOn: SendContactInfoEmailFunction
    Properties:
      BatchSize: 100
      EventSourceArn: !GetAtt AddContactsTable.StreamArn
      FunctionName: !Ref SendContactInfoEmailFunction
      StartingPosition: LATEST
      Enabled: true
      BisectBatchOnFunctionError: false 
      TumblingWindowInSeconds: 0
```

### Förklaring:

- **EventSourceMapping**: Skapar en trigger för Lambda-funktionen `SendContactInfoEmailFunction`, som nu triggas av händelser (nya poster) i DynamoDB-streamen för `AddContactsTable`.
- **BatchSize**: Maximalt antal poster som skickas till funktionen på en gång.
- **EventSourceArn**: Referens till DynamoDB-streamens ARN, som är kopplad till vår `AddContactsTable`.
- **StartingPosition**: Anger att funktionen ska börja bearbeta nya poster från den senaste händelsen.
- **BisectBatchOnFunctionError**: När satt till `false` behandlas hela batchen vid fel.
- **TumblingWindowInSeconds**: Anger att batcherna ska skickas utan någon specifik tidsfönster.

### Kör:

1. Lägg till koden i din `cloudformation.yaml`-fil.
2. Kör deploy-skriptet:

   ```bash
   ./deploy.sh
   ```

### Verifiera:

1. Gå till **AWS Console** och navigera till **Lambda**.
2. Kontrollera att triggern har skapats för **SendContactInfoEmailFunction**.
3. Testa funktionaliteten genom att lägga till en ny post i DynamoDB via API Gateway.
4. Kontrollera att e-postmeddelandet skickas via SES efter att posten har lagts till i DynamoDB och att det innehåller kontaktinformationen.

### Test:

För att testa detta:

1. Gå till **API Gateway** i AWS Console.
2. Navigera till den nya API som skapades för kontaktformuläret.
3. Välj **Test** och välj **POST** som metod.
4. Lägg till följande request body:

   ```json
   {
     "name": "test",
     "email": "test@email.com",
     "msg": "testar så funktionen fungerar"
   }
   ```

5. Kör testet och verifiera att e-postmeddelandet skickas via SES och att informationen visas korrekt i e-postmeddelandet.

[⬆️ Till toppen](#top)






## Steg 12: Lägg till S3 Bucket för att lagra webbplatsens filer

I det här steget kommer vi att skapa en S3-bucket för att lagra webbplatsens filer, som kan inkludera HTML, CSS, JavaScript och andra tillgångar för kontaktformuläret.

### Lägg till kod i `cloudformation.yaml`:

```yaml
Resources:
  # Tidigare definierade resurser...

  # S3 Bucket with a unique name including account ID, region, and stack name
  ContactFormBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'contact-form-bucket-${AWS::AccountId}-${AWS::Region}-${AWS::StackName}'
```

### Förklaring:

- **S3 Bucket**: Skapar en S3-bucket för att lagra webbplatsens filer.
- **BucketName**: Namnet på bucketen genereras dynamiskt och inkluderar AWS-kontots ID, region och stackens namn för att säkerställa att bucketen får ett unikt namn.

### Kör:

1. Lägg till koden i din `cloudformation.yaml`-fil.
2. Kör deploy-skriptet:

   ```bash
   ./deploy.sh
   ```

### Verifiera:

1. Gå till **AWS Console** och navigera till **S3**.
2. Kontrollera att en S3-bucket med namnet som definieras i koden har skapats.
3. Verifiera att du kan ladda upp webbplatsens filer till denna bucket och att du kan komma åt dem via en URL om den är offentlig.

[⬆️ Till toppen](#top)







## Steg 13: Lägg till CloudFront Distribution framför S3-bucket

I det här steget kommer vi att skapa en CloudFront-distribution för att leverera innehållet från S3-bucketen och säkerställa att åtkomst till innehållet är säker genom att använda Origin Access Control (OAC).

### Lägg till kod i `cloudformation.yaml`:

```yaml
Resources:
  # Tidigare definierade resurser...

  # Origin Access Control (OAC) for CloudFront
  ContactFormOAC:
    Type: AWS::CloudFront::OriginAccessControl
    Properties:
      OriginAccessControlConfig:
        Name: "ContactFormOAC"
        SigningBehavior: "always"
        SigningProtocol: "sigv4"
        OriginAccessControlOriginType: "s3"

  # CloudFront Distribution with S3 as origin using OAC
  ContactFormCloudFront:
    Type: AWS::CloudFront::Distribution
    DependsOn: 
      - ContactFormBucket
      - InvokeHtmlUpload
    Properties:
      DistributionConfig:
        Origins:
          - Id: 'S3Origin'
            DomainName: !GetAtt ContactFormBucket.DomainName
            S3OriginConfig: {}
            OriginAccessControlId: !Ref ContactFormOAC  # Link the OAC here
        Enabled: true
        DefaultRootObject: 'index.html'
        DefaultCacheBehavior:
          TargetOriginId: 'S3Origin'
          ViewerProtocolPolicy: 'redirect-to-https'
          AllowedMethods:
            - 'GET'
            - 'HEAD'
          ForwardedValues:
            QueryString: false
            Cookies:
              Forward: 'none'
        PriceClass: 'PriceClass_100'
        ViewerCertificate:
          CloudFrontDefaultCertificate: true
```

### Förklaring:

- **Origin Access Control (OAC)**: Skapar en Origin Access Control för att säkerställa att CloudFront kan hämta innehåll från S3 utan att exponera S3-bucketens URL direkt för användarna.
- **CloudFront Distribution**: Skapar en CloudFront-distribution som använder S3-bucketen som ursprung för att leverera webbplatsens filer via en CDN, med HTTPS-skydd och cachebeteende.
- **PriceClass**: Använder `PriceClass_100`, som är den mest kostnadseffektiva klassen och täcker de flesta regioner.

### Kör:

1. Lägg till koden i din `cloudformation.yaml`-fil.
2. Kör deploy-skriptet:

   ```bash
   ./deploy.sh
   ```

### Verifiera:

1. Gå till **AWS Console** och navigera till **CloudFront**.
2. Kontrollera att en ny CloudFront-distribution har skapats och att den använder din S3-bucket som ursprung.
3. Kontrollera att du kan komma åt webbplatsen via den genererade CloudFront-URL:en.

[⬆️ Till toppen](#top)











## Steg 14: Lägg till rättigheter för S3-bucket

I det här steget kommer vi att skapa en S3 Bucket Policy som endast tillåter åtkomst till S3-bucketen från CloudFront. Detta säkerställer att innehållet i S3-bucketen kan nås enbart via den distribuerade CloudFront-URL:en.

### Lägg till kod i `cloudformation.yaml`:

```yaml
Resources:
  # Tidigare definierade resurser...

  # S3 Bucket Policy to allow access only from CloudFront
  S3BucketPolicy:
    Type: AWS::S3::BucketPolicy
    DependsOn:
      - ContactFormBucket
      - ContactFormCloudFront
    Properties:
      Bucket: !Ref ContactFormBucket
      PolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Sid: AllowCloudFrontAccess
            Effect: Allow
            Principal:
              Service: "cloudfront.amazonaws.com"
            Action: "s3:GetObject"
            Resource: !Sub "arn:aws:s3:::contact-form-bucket-${AWS::AccountId}-${AWS::Region}-${AWS::StackName}/*"
            Condition:
              StringEquals:
                AWS:SourceArn: !Sub "arn:aws:cloudfront::${AWS::AccountId}:distribution/${ContactFormCloudFront}"
```

### Förklaring:

- **S3 Bucket Policy**: Den här policyn gör att CloudFront kan komma åt objekt i S3-bucketen, men endast från den specifika CloudFront-distributionen som vi definierade tidigare.
- **Policydocument**: Specifikt definieras att endast CloudFront-distributionen får hämta objekt från S3-bucketen genom att kontrollera `AWS:SourceArn` för CloudFront-distributionen.

### Kör:

1. Lägg till koden i din `cloudformation.yaml`-fil.
2. Kör deploy-skriptet:

   ```bash
   ./deploy.sh
   ```

### Verifiera:

1. Gå till **AWS Console** och navigera till **S3**.
2. Kontrollera att rättigheten har applicerats på S3-bucketen och att den nu är åtkomlig endast via CloudFront-distributionen.

Testet kan göras genom att försöka komma åt en fil från S3-bucketen direkt via URL, vilket inte ska vara tillåtet. Åtkomst ska endast vara möjlig via CloudFront-distributionen.

[⬆️ Till toppen](#top)









## Steg 15: Lägg till IAM-roll för Lambda att ladda upp till S3-bucket

I det här steget skapar vi en IAM-roll som tillåter Lambda-funktionen att ladda upp filer till den skapade S3-bucketen. Denna roll ger nödvändiga rättigheter för att Lambda ska kunna skriva och hämta filer i S3.

### Lägg till kod i `cloudformation.yaml`:

```yaml
Resources:
  # Tidigare definierade resurser...

  # IAM Role for Lambda Function to Access S3
  LambdaS3UploadRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub "LambdaS3UploadRole-${AWS::StackName}"
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal:
              Service: 
                - lambda.amazonaws.com
            Action: "sts:AssumeRole"
      Policies:
        - PolicyName: S3AccessPolicy
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Effect: Allow
                Action:
                  - "s3:PutObject"
                  - "s3:PutObjectAcl"
                  - "s3:GetObject"
                Resource: 
                  - !Sub "${ContactFormBucket.Arn}/*"
```

### Förklaring:
- **IAM-roll**: Den här rollen ger Lambda-funktionen de nödvändiga rättigheterna för att läsa och skriva objekt i den angivna S3-bucketen.
- **Policy**: Politiska åtgärder som tillåter `s3:PutObject`, `s3:PutObjectAcl` och `s3:GetObject`, vilket gör det möjligt för Lambda att ladda upp, hämta och sätta rättigheter på objekt i S3-bucketen.

### Kör:
1. Lägg till koden i din `cloudformation.yaml`-fil.
2. Kör deploy-skriptet:

   ```bash
   ./deploy.sh
   ```

### Verifiera:
1. Gå till **AWS Console** och navigera till **IAM**.
2. Kontrollera att rollen **LambdaS3UploadRole** har skapats.
3. Kontrollera att policyn är korrekt tillämpad och att Lambda-funktionen har behörighet att interagera med S3-bucketen.

[⬆️ Till toppen](#top)









## Steg 16: Lägg till Lambda-funktion för att ladda upp `index.html` till S3-bucket vid deploy

I det här steget skapar vi en Lambda-funktion som laddar upp en `index.html`-fil till den skapade S3-bucketen. Funktionen triggas av en **Custom Resource** vid deploy, och ger en respons till CloudFormation när filen har laddats upp.

### Lägg till kod i `cloudformation.yaml`:

```yaml
Resources:
  # Tidigare definierade resurser...

  # Lambda function to handle file upload with CloudFormation response
  S3LambdaFunction:
    Type: AWS::Lambda::Function
    DependsOn:
      - LambdaS3UploadRole
      - ContactFormBucket
      - ApiGatewayRestApi
    Properties:
      FunctionName: UploadHtmlFunction
      Handler: index.lambda_handler
      Role: !GetAtt LambdaS3UploadRole.Arn
      Runtime: python3.13
      Environment:
        Variables:
          BUCKET_NAME: !Ref ContactFormBucket
          API_ID: !Ref ApiGatewayRestApi
          API_REGION: !Ref "AWS::Region"
          API_STAGE: "default"
      Code:
        ZipFile: |
          import boto3
          import os
          import json
          import urllib.request

          s3_client = boto3.client('s3')

          # Function to send a response to CloudFormation
          def send_response(event, context, status, response_data):
              response_url = event['ResponseURL']
              response_body = json.dumps({
                  'Status': status,
                  'Reason': 'See the details in CloudWatch Log Stream: ' + context.log_stream_name,
                  'PhysicalResourceId': context.log_stream_name,
                  'StackId': event['StackId'],
                  'RequestId': event['RequestId'],
                  'LogicalResourceId': event['LogicalResourceId'],
                  'Data': response_data
              })

              headers = {
                  'content-type': '',
                  'content-length': str(len(response_body))
              }

              try:
                  request = urllib.request.Request(
                      response_url,
                      data=response_body.encode('utf-8'),
                      headers=headers,
                      method='PUT'
                  )
                  urllib.request.urlopen(request)
                  print("Response sent to CloudFormation successfully.")
              except Exception as e:
                  print(f"Failed to send response: {e}")

          # Lambda handler function
          def lambda_handler(event, context):
              print("Received event:", json.dumps(event))

              # Define bucket name and file content
              bucket_name = os.environ.get('BUCKET_NAME', 'default-bucket-name')
              api_id = os.environ.get('API_ID', '')
              api_region = os.environ.get('API_REGION', '')
              api_stage = os.environ.get('API_STAGE', 'default')

              # Construct the API endpoint URL
              api_endpoint = f"https://{api_id}.execute-api.{api_region}.amazonaws.com/{api_stage}/AddContactInfo"
              
              html_content = f"""
              <!DOCTYPE html>
              <html>
              <head>
                  <title>Contact Form</title>
                  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
              </head>
              <body>
                  <div class="container">
                      <h1>Contact Form</h1>
                      <form id="contactForm" method="POST">
                          <div class="form-group">
                              <label for="name">Name:</label>
                              <input type="text" class="form-control" id="name" name="name" required>
                          </div>
                          <div class="form-group">
                              <label for="email">Email:</label>
                              <input type="email" class="form-control" id="email" name="email" required>
                          </div>
                          <div class="form-group">
                              <label for="msg">Message:</label>
                              <textarea class="form-control" id="msg" name="msg" rows="4" cols="50" required></textarea>
                          </div>
                          <input type="submit" class="btn btn-primary" value="Submit">
                      </form>
                  </div>
                  <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
                  <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.5.0/dist/js/bootstrap.min.js"></script>
                  <script>
                      const ApiUrl = "{api_endpoint}";
                      document.getElementById("contactForm").addEventListener("submit", function(event) {{
                          event.preventDefault();
                          var formData = {{
                              name: document.getElementById("name").value,
                              email: document.getElementById("email").value,
                              msg: document.getElementById("msg").value
                          }};
                          fetch(ApiUrl, {{
                              method: "POST",
                              body: JSON.stringify(formData)
                          }})
                          .then(response => {{
                              if (response.ok) {{
                                  alert("Form submitted successfully");
                              }} else {{
                                  alert("Form submission failed");
                              }}
                          }})
                          .catch(error => {{
                              console.error("An error occurred:", error);
                          }});
                      }});
                  </script>
              </body>
              </html>
              """

              try:
                  # Upload the HTML content to S3 bucket
                  s3_client.put_object(
                      Bucket=bucket_name,
                      Key='index.html',
                      Body=html_content,
                      ContentType='text/html'
                  )
                  print(f"File uploaded successfully to {bucket_name}/index.html")

                  # Send a success response to CloudFormation
                  send_response(event, context, 'SUCCESS', {'Message': 'index.html uploaded successfully'})

              except Exception as e:
                  print(f"Error uploading file: {e}")
                  # Send a failure response to CloudFormation
                  send_response(event, context, 'FAILED', {'Message': str(e)})

  # Custom resource to invoke Lambda function
  InvokeHtmlUpload:
    Type: AWS::CloudFormation::CustomResource
    DependsOn:
      - ContactFormBucket
      - ApiGatewayRestApi
    Properties:
      ServiceToken: !GetAtt S3LambdaFunction.Arn

  # Create a CodeStar connection to GitHub
  GitHubConnection:
    Type: AWS::CodeStarConnections::Connection
    Properties:
      ConnectionName: GitHubConnectionToMyRepo
      ProviderType: GitHub
```

### Förklaring:
- **Lambda-funktion**: Funktionen `S3LambdaFunction` laddar upp en HTML-fil till S3-bucketen `ContactFormBucket`. Den genererade HTML-filen innehåller ett kontaktformulär och en JavaScript-funktion som skickar formulärdata till API Gateway.
- **Custom Resource**: Vi använder en Custom Resource för att trigga Lambda-funktionen vid deploy.
- **API-länk**: Lambda-funktionen genererar en HTML-fil där API Gateway-endpointen inkluderas för att ta emot data från kontaktformuläret.

### Kör:
1. Lägg till koden i din `cloudformation.yaml`-fil.
2. Kör deploy-skriptet:

   ```bash
   ./deploy.sh
   ```

### Verifiera:
1. Gå till **AWS Console** och navigera till **Lambda**.
2. Kontrollera att Lambda-funktionen har skapats och körts korrekt.
3. Gå till **S3** och kontrollera att filen `index.html` har laddats upp till rätt bucket.
4. Testa att webbsidan fungerar och att formulärdata kan skickas via API Gateway.

[⬆️ Till toppen](#top)







## Steg 17: Lägg till S3-bucket för CodePipeline artefakter

I det här steget skapar vi en S3-bucket som ska användas för att lagra artefakter från CodePipeline. Denna bucket kommer att innehålla koden och alla filer som används för att distribuera applikationen.

### Lägg till kod i `cloudformation.yaml`:

```yaml
Resources:
  # Tidigare definierade resurser...

  # Create an S3 bucket for storing artifacts
  MyArtifactBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'artifact-bucket-${AWS::AccountId}-${AWS::Region}-${AWS::StackName}'
```

### Förklaring:
- **S3 Bucket för artefakter**: Den nya bucket `MyArtifactBucket` används för att lagra artefakter från CodePipeline. Namnet på bucketen genereras dynamiskt baserat på kontoinformation, region och stack-namn för att säkerställa att det är unikt.

### Kör:
1. Lägg till koden i din `cloudformation.yaml`-fil.
2. Kör deploy-skriptet:

   ```bash
   ./deploy.sh
   ```

### Verifiera:
1. Gå till **AWS Console** och navigera till **S3**.
2. Kontrollera att en ny bucket med namnet `artifact-bucket-<AccountId>-<Region>-<StackName>` har skapats.
3. Verifiera att artefakter lagras korrekt i denna bucket när CodePipeline körs.

[⬆️ Till toppen](#top)







## Steg 18: Lägg till IAM Roll för Lambda och CodePipeline

I det här steget skapar vi en IAM-roll som både **Lambda** och **CodePipeline** kommer att använda för att få nödvändiga rättigheter för att interagera med olika resurser som S3, GitHub, CloudWatch, och CloudFront.

### Lägg till kod i `cloudformation.yaml`:

```yaml
Resources:
  # Tidigare definierade resurser...

  # Combined IAM Role for CodePipeline and Lambda (using the name CodePipelineRole)
  CodePipelineRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - codepipeline.amazonaws.com
                - codebuild.amazonaws.com
                - lambda.amazonaws.com
            Action: sts:AssumeRole
      Policies:
        - PolicyName: CombinedCodePipelinePolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              # Permissions for CodePipeline to interact with S3 and GitHub
              - Effect: Allow
                Action:
                  - s3:GetObject
                  - s3:PutObject
                  - s3:GetBucketVersioning
                  - s3:PutBucketAcl
                  - codestar-connections:UseConnection
                Resource:
                  - !GetAtt MyArtifactBucket.Arn
                  - !Sub "${MyArtifactBucket.Arn}/*"
                  - !Sub "${ContactFormBucket.Arn}/*"
                  - !Ref GitHubConnection  # GitHub connection resource

              # Permissions for CodePipeline to create CloudWatch log groups, log streams, and log events
              - Effect: Allow
                Action:
                  - logs:CreateLogGroup
                  - logs:CreateLogStream
                  - logs:PutLogEvents
                Resource: "*"

              # Permissions to allow CodePipeline to pass IAM roles
              - Effect: Allow
                Action: iam:PassRole
                Resource: '*'  # Allow passing any IAM role (can be restricted to specific roles)

              # Permissions for Lambda to invoke CloudFront invalidation
              - Effect: Allow
                Action:
                  - cloudfront:CreateInvalidation
                  - lambda:InvokeFunction
                Resource: "*"  # Adjust to a specific CloudFront distribution ARN if possible

              # **New Permissions for CodePipeline Job Status Update**
              - Effect: Allow
                Action:
                  - codepipeline:PutJobSuccessResult
                  - codepipeline:PutJobFailureResult
                Resource: "*"  # Optionally, you can restrict this to specific pipelines if necessary
```

### Förklaring:
- **CodePipelineRole**: Den här rollen tilldelas både **CodePipeline** och **Lambda** så att de kan utföra nödvändiga åtgärder, som att interagera med S3-buckets, GitHub, CloudWatch och CloudFront.
- **Policy**: Den definierade policyn tillåter CodePipeline att arbeta med S3, GitHub, loggar och hantera IAM-roller samt Lambda-funktioner som att skapa CloudFront-invalideringar.

### Kör:
1. Lägg till koden i din `cloudformation.yaml`-fil.
2. Kör deploy-skriptet:

   ```bash
   ./deploy.sh
   ```

### Verifiera:
1. Gå till **AWS Console** och navigera till **IAM > Roles**.
2. Kontrollera att rollen `CodePipelineRole` har skapats och att den har tilldelats rätt policyer.
3. Kontrollera att **CodePipeline** och **Lambda** har rättigheter att interagera med de definierade resurserna.

[⬆️ Till toppen](#top)







## Steg 19: Lägg till Lambda Funktion för CloudFront Invalidering

I det här steget skapar vi en Lambda-funktion som kommer att användas för att skapa en CloudFront-invalidering. När en uppdatering görs genom CodePipeline, kommer denna Lambda-funktion att invalidiera CloudFront-cachen för att säkerställa att användarna får den senaste versionen av resurserna.

### Lägg till kod i `cloudformation.yaml`:

```yaml
Resources:
  # Tidigare definierade resurser...

  # Lambda Function for CloudFront Invalidation
  CloudFrontInvalidationFunction:
    Type: AWS::Lambda::Function
    DependsOn:
      - CodePipelineRole  # Ensure the CodePipelineRole is created first
      - ContactFormCloudFront
    Properties:
      FunctionName: CloudFrontInvalidationFunction
      Handler: index.lambda_handler
      Runtime: python3.9
      Role: !GetAtt CodePipelineRole.Arn  # Use CodePipelineRole here
      Environment:
        Variables:
          DISTRIBUTION_ID: !Ref ContactFormCloudFront
      Code:
        ZipFile: |
          import boto3
          import os

          cloudfront = boto3.client('cloudfront')
          codepipeline = boto3.client('codepipeline')

          def lambda_handler(event, context):
              distribution_id = os.getenv('DISTRIBUTION_ID')
              
              # Extract jobId for the CodePipeline action
              job_id = event['CodePipeline.job']['id']
              
              try:
                  # Create CloudFront invalidation
                  response = cloudfront.create_invalidation(
                      DistributionId=distribution_id,
                      InvalidationBatch={
                          'Paths': {
                              'Quantity': 1,
                              'Items': ['/*']
                          },
                          'CallerReference': str(context.aws_request_id)
                      }
                  )
                  
                  print(f"Invalidation created: {response}")
                  
                  # Notify CodePipeline of successful completion
                  codepipeline.put_job_success_result(jobId=job_id)
                  
                  return {
                      'statusCode': 200,
                      'body': {
                          'status': 'Succeeded',
                          'message': f"Invalidation created with ID: {response['Invalidation']['Id']}"
                      }
                  }
              
              except Exception as e:
                  # Notify CodePipeline of failure
                  print(f"Error: {str(e)}")
                  codepipeline.put_job_failure_result(
                      jobId=job_id,
                      failureDetails={
                          'message': str(e),
                          'type': 'JobFailed'
                      }
                  )
                  
                  return {
                      'statusCode': 500,
                      'body': {
                          'status': 'Failed',
                          'message': f"Error during invalidation: {str(e)}"
                      }
                  }
```

### Förklaring:
- **CloudFrontInvalidationFunction**: Denna Lambda-funktion ansvarar för att skapa en invalidation i CloudFront, vilket gör att cachen rensas och användare får den uppdaterade versionen av resursen.
- **Environment Variables**: Miljövariabeln `DISTRIBUTION_ID` används för att ange CloudFront-distributionens ID som Lambda-funktionen kommer att invalidiera.
- **CloudFront API**: Lambda-funktionen använder `cloudfront.create_invalidation()` för att skapa en invalidation på CloudFront.
- **CodePipeline**: Lambda-funktionen interagerar med CodePipeline och rapporterar resultatet tillbaka (om invalidationen lyckas eller misslyckas).

### Kör:
1. Lägg till koden i din `cloudformation.yaml`-fil.
2. Kör deploy-skriptet:

   ```bash
   ./deploy.sh
   ```

### Verifiera:
1. Gå till **AWS Console** och navigera till **Lambda**.
2. Kontrollera att Lambda-funktionen `CloudFrontInvalidationFunction` har skapats och att den har rätt miljövariabler och behörigheter.
3. Testa genom att köra en pipeline och verifiera att invalidationen skapas på CloudFront.

[⬆️ Till toppen](#top)







## Steg 20: Lägg till CodePipeline

I detta steg skapar vi en CodePipeline som automatiskt bygger och distribuerar applikationen. Pipeline kommer att innehålla tre huvudsakliga steg: **Source**, **Deploy**, och **InvalidateCache**. Vi kommer att använda GitHub som källan för koden, S3 för distributionen, och Lambda för att invalidiera CloudFront-cachen.

### Lägg till kod i `cloudformation.yaml`:

```yaml
Resources:
  # Tidigare definierade resurser...

  # CodePipeline Resource
  MyCodePipeline:
    Type: AWS::CodePipeline::Pipeline
    DependsOn:
      - CodePipelineRole
      - MyArtifactBucket
      - GitHubConnection
      - ContactFormBucket
      - CloudFrontInvalidationFunction
    Properties:
      Name: MyPipeline
      RoleArn: !GetAtt CodePipelineRole.Arn  # Use CodePipelineRole here

      # Artifact store
      ArtifactStore:
        Type: S3
        Location: !Ref MyArtifactBucket

      # Pipeline stages (source, build, and deploy)
      Stages:
        - Name: Source
          Actions:
            - Name: GitHubSource
              ActionTypeId:
                Category: Source
                Owner: AWS
                Provider: CodeStarSourceConnection
                Version: 1
              OutputArtifacts:
                - Name: SourceOutput
              Configuration:
                ConnectionArn: !Ref GitHubConnection
                FullRepositoryId: !Ref GitHubRepositoryId
                BranchName: main

        - Name: Deploy
          Actions:
            - Name: S3Deploy
              ActionTypeId:
                Category: Deploy
                Owner: AWS
                Provider: S3
                Version: 1
              InputArtifacts:
                - Name: SourceOutput
              Configuration:
                BucketName: !Ref ContactFormBucket
                Extract: 'true'

        - Name: InvalidateCache
          Actions:
            - Name: CloudFrontInvalidation
              ActionTypeId:
                Category: Invoke
                Owner: AWS
                Provider: Lambda
                Version: 1
              Configuration:
                FunctionName: !Ref CloudFrontInvalidationFunction
              RoleArn: !GetAtt CodePipelineRole.Arn  # Use CodePipelineRole here
              RunOrder: 1
              OutputArtifacts:  # Add this if you want to pass data between pipeline stages
                - Name: InvalidationOutput
```

### Förklaring:

- **Source**: Den här fasen hämtar koden från GitHub, med hjälp av en CodeStarSourceConnection.
- **Deploy**: I denna fas laddas koden upp till S3-bucketen, där applikationen lagras och distribueras.
- **InvalidateCache**: Denna fas triggar Lambda-funktionen som invalidierar CloudFront-cachen och säkerställer att den senaste versionen av webbplatsen är tillgänglig för användarna.
- **ArtifactStore**: En S3-bucket används för att lagra artefakter mellan pipeline-stegen.

### Uppdaterad `deploy.sh`:

För att köra denna deployment måste vi också uppdatera vårt `deploy.sh`-skript så att det deployar CloudFormation-stack och tar hänsyn till de parametrar vi definierar i `.env`-filen.

Här är den uppdaterade versionen av skriptet:

```bash
#!/bin/bash

# Ladda miljövariabler från .env-filen
source .env

# Sätt variabler för CloudFormation-mallfilen och stacknamn
TEMPLATE_FILE="CloudFormation.yaml"  # Ändra denna till din CloudFormation mallfilens väg
STACK_NAME="uppgift3"  # Ändra detta till ditt stacknamn

# Deploya CloudFormation stacken med de angivna miljövariablerna
aws cloudformation deploy \
  --template-file "$TEMPLATE_FILE" \
  --stack-name "$STACK_NAME" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    FromEmail="$FROM_EMAIL" \
    ToEmail="$TO_EMAIL" \
    GitHubRepositoryId="$GITHUB_REPOSITORY_ID"
```

### Förklaring:

- **`source .env`**: Detta kommando laddar miljövariabler från en `.env`-fil. Se till att du har denna fil med rätt variabler (som `FROM_EMAIL`, `TO_EMAIL`, `GITHUB_REPOSITORY_ID`, etc.) definierade i din arbetskatalog.
  
- **CloudFormation deployment**:
  - **`aws cloudformation deploy`**: Detta kommando deployar din CloudFormation-stack, vilket skapar eller uppdaterar resurser baserade på `CloudFormation.yaml`.
  - **`--capabilities CAPABILITY_NAMED_IAM`**: Denna flagga krävs om du skapar IAM-roller eller andra IAM-resurser.
  - **`--parameter-overrides`**: Här anger du parametrarna som används av CloudFormation-mallen, inklusive t.ex. e-postadresser och GitHub-repository-ID.

### Se till att `.env`-filen innehåller:

```bash
FROM_EMAIL="din-email@domain.com"
TO_EMAIL="mottagar-email@domain.com"
GITHUB_REPOSITORY_ID="användarnamn/repository"
```

När du har gjort dessa uppdateringar och sparat `.env`-filen, kan du köra skriptet för att deploya din CloudFormation-stack:

```bash
./deploy.sh
```

### Verifiering:

1. När deployment är klar, gå till **AWS Console** och navigera till **CodePipeline**.
2. Kontrollera att pipeline `MyPipeline` har skapats och att alla steg finns där (Source, Deploy, InvalidateCache).
3. Starta en pipeline-körning och verifiera att koden distribueras korrekt till S3 och att CloudFront-invalideringen sker.
4. Kontrollera **CloudWatch Logs** för att verifiera att Lambda-funktionen körs korrekt under invalidationssteget.

[⬆️ Till toppen](#top)








## Steg 21: Slutför autentisering av GitHub Connect via AWS Console

För att slutföra autentiseringen och verifiera GitHub-anslutningen, följ dessa steg:

### Steg-för-steg guide:

1. **Öppna Developer Tools i AWS Console**:
   - Gå till **AWS Management Console**.
   - I sökfältet, skriv **Developer Tools** och välj det från listan.

2. **Navigera till GitHub Connections**:
   - Under **Settings** (inställningar), välj **Connections**.
   - Här ska du se den GitHub-anslutning som skapades via CloudFormation.

3. **Verifiera GitHub-anslutningen**:
   - Klicka på den skapade GitHub-anslutningen.
   - Ett popup-fönster kommer att öppnas i AWS där du får verifiera anslutningen.
   - Detta popup-fönster kommer att omdirigera dig till GitHub för att ge AWS åtkomst till ditt GitHub-konto.

4. **Godkänn åtkomst och välj repository**:
   - När du omdirigeras till GitHub, logga in om du inte redan är inloggad.
   - Ge AWS tillgång till ditt GitHub-konto genom att godkänna åtkomstbegäran.
   - Välj rätt repository som ska användas för din pipeline och klicka på **Authorize**.

### Efter verifiering:
När GitHub-anslutningen har verifierats och slutförts, kommer AWS att ha åtkomst till det valda repositoryt, och du kan använda det i din pipeline-konfiguration.

[⬆️ Till toppen](#top)









## Steg 22: Ladda upp index.html till GitHub Repository från S3

För att lägga till en ny `index.html`-fil till ditt GitHub-repository, följ dessa steg:

### Steg-för-steg guide:

1. **Hämta index.html från S3**:
   - Gå till **AWS Management Console** och öppna **S3**.
   - Leta upp den S3-bucket där `index.html` ska finnas (t.ex., `ContactFormBucket`).
   - Klicka på filen `index.html` (om den inte finns, skapa en fil och ladda upp den).
   - Om du redan har filen, ladda ner den genom att klicka på **Download**.

2. **Öppna GitHub Repository**:
   - Gå till **GitHub** och logga in på ditt konto.
   - Navigera till det repository där du vill ladda upp filen.
   - Om du inte redan har en lokal kopia av repositoryt, klona det till din dator:
     ```bash
     git clone https://github.com/username/repository-name.git
     ```
     Byt ut `username` och `repository-name` med det aktuella namnet på din GitHub-användare och repository.

3. **Lägg till index.html till ditt GitHub Repository**:
   - Kopiera den nedladdade `index.html`-filen till din lokala kopia av repositoryt.
   - Gå till din terminal eller kommandoprompt och kör följande kommandon:
     ```bash
     cd /path/to/your/repository
     git add index.html
     git commit -m "Add index.html"
     git push origin main
     ```

4. **Verifiera ändringar på GitHub**:
   - Gå tillbaka till GitHub och bekräfta att `index.html` nu finns i repositoryt.
   - Den nya filen kommer nu att vara en del av repositoryt och kan användas för vidare deployment eller integrationer.

Efter att ha slutfört dessa steg, har `index.html` nu lagts till i ditt GitHub-repository och kan användas för framtida deployment eller pipeline-konfiguration.

[⬆️ Till toppen](#top)








## Steg 23: Pusha en förändring av `index.html`, verifiera att pipeline kör och testa CloudFront invalidation

Följ dessa steg för att pusha en förändring till `index.html`, kontrollera att din pipeline körs och verifiera att CloudFront-invalidationen har genomförts.

### Steg-för-steg guide:

1. **Ändra `index.html`-filen**:
   - Öppna din lokala kopia av GitHub-repositoryt.
   - Gör den önskade ändringen i filen `index.html` (t.ex., ändra texten, lägga till en ny sektion eller uppdatera innehåll).

2. **Pusha ändringen till GitHub**:
   - När du har gjort dina ändringar, spara filen och öppna terminalen.
   - Kör följande kommandon för att lägga till, commita och pusha ändringarna till ditt GitHub-repository:
     ```bash
     git add index.html
     git commit -m "Update index.html with new changes"
     git push origin main
     ```

3. **Verifiera att CodePipeline kör**:
   - Gå till **AWS Management Console** och öppna **CodePipeline**.
   - Leta upp din pipeline (t.ex., `MyPipeline`).
   - Verifiera att en ny pipeline-exekvering har startat efter din push till GitHub.
     - Om pipeline inte startar automatiskt, kontrollera om GitHub-kopplingen är korrekt och om den är konfigurerad för att trigga vid varje push till repositoryt.
   - Under fliken **Stages** kan du se status för varje steg (Source, Deploy, etc.).
   - Om ett steg misslyckas, klicka på det för att få mer detaljer om vad som kan ha gått fel.

4. **Verifiera att CloudFront-invalidation har körts**:
   - När pipeline-exekveringen är klar, gå till **AWS Management Console** och öppna **CloudFront**.
   - Leta upp din CloudFront-distribution (t.ex., `ContactFormCloudFront`).
   - Under fliken **Invalidations**, kontrollera om en invalidation har skapats efter deployment.
   - Om invalidationen har körts korrekt, kommer statusen att vara "Completed" för den senaste invalidationen.

5. **Testa den uppdaterade sidan**:
   - Gå till den URL som är kopplad till din CloudFront-distribution.
   - Verifiera att ändringarna i `index.html` syns på webbplatsen.
     - Om sidan inte uppdateras direkt, vänta några minuter för att ge CloudFront cache att uppdateras.
     - Rensa din webbläsares cache eller använd inkognitoläge för att testa ändringarna.

Efter att ha följt dessa steg ska din förändring av `index.html` ha pushats till GitHub, pipeline köras korrekt och CloudFront-invalidationen ha genomförts. Du kan nu testa den uppdaterade sidan för att säkerställa att allt fungerar som förväntat.

[⬆️ Till toppen](#top)







## Steg 24: Rensa upp och ta bort CloudFormation-resurser

För att säkerställa att du inte betalar för onödiga AWS-resurser, följer du dessa steg för att ta bort CloudFormation-stacken och rensa alla relaterade resurser:

### Steg-för-steg guide:

1. **Töm S3-buckets**:
   - Gå till **AWS S3** i Management Console.
   - Öppna de S3-buckets som skapades av CloudFormation (t.ex., `MyArtifactBucket`, `ContactFormBucket`).
   - Ta bort alla filer som finns i dessa buckets.
     - Välj alla objekt i bucketen och välj **Delete**.
     - Bekräfta att du vill ta bort objekten.

2. **Ta bort CloudFormation-stacken**:
   - Gå till **AWS CloudFormation** i Management Console.
   - Leta upp den stack du skapade (t.ex., `MyStack` eller den stack du använde för att skapa din miljö).
   - Välj stacken och klicka på **Delete** för att ta bort alla resurser som är kopplade till den.
     - När du tar bort stacken kommer alla resurser (t.ex., S3-buckets, IAM-roller, Lambda-funktioner, CodePipeline) som skapades av CloudFormation att tas bort automatiskt.

3. **Verifiera att alla resurser har tagits bort**:
   - Gå igenom de olika AWS-tjänsterna som du använde för din lösning och verifiera att alla relaterade resurser har tagits bort.
     - **S3**: Se till att alla buckets är tomma eller borttagna.
     - **IAM**: Kontrollera att eventuella IAM-roller eller policies som skapades av CloudFormation inte längre finns.
     - **Lambda**: Kontrollera att Lambda-funktionerna inte finns kvar.
     - **CloudFront**: Kontrollera att din CloudFront-distribution har tagits bort om den inte längre behövs.
     - **CodePipeline**: Se till att inga pipelines eller relaterade artefakter finns kvar.

4. **Rensa upp eventuella andra resurser**:
   - Om du har andra resurser som skapades manuellt (t.ex., GitHub-kopplingar, API Gateway), ta bort dessa också för att undvika extra kostnader.

Genom att följa dessa steg ser du till att alla resurser som skapades för projektet tas bort och att du slipper onödiga kostnader för AWS-tjänster.

[⬆️ Till toppen](#top)