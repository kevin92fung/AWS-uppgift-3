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







Här är ett exempel på hur du kan lägga till den här koden i din `cloudformation.yaml`-fil för att referera till tidigare definierade resurser:

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

- **Tidigare definierade resurser**: Här kan du lägga till andra resurser som du har definierat tidigare i din `cloudformation.yaml`-fil, som till exempel S3-bucket, Lambda-funktioner, CloudFront-distributioner eller andra nödvändiga resurser.
- **S3 Bucket Policy**: Den här policyresursen definierar rättigheter för åtkomst till S3-bucketen via CloudFront och begränsar åtkomsten till endast CloudFront-distributionen.

När du implementerar detta i din CloudFormation-stack kommer resursen `S3BucketPolicy` att tillämpas för din S3-bucket och säkerställa att den endast är åtkomlig via CloudFront.

[⬆️ Till toppen](#top)