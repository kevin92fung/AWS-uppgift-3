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

## Steg 1: Skapa GitHub Repository
1. Gå till [GitHub](https://github.com/) och logga in.
2. Klicka på knappen **New** i övre högra hörnet för att skapa ett nytt repository.
3. Ge repositoryt ett namn (t.ex. `aws-contact-form`) och välj om det ska vara publikt eller privat.
4. Klicka på **Create repository** för att slutföra.

## Steg 2: Skapa `.env`-fil
1. Gå till din hemkatalog och skapa en ny katalog för projektet:

```bash
cd ~
mkdir serverless
cd serverless
```

2. Skapa `.env`-filen i den nya katalogen:

```bash
touch .env
```

3. Lägg sedan till följande innehåll i `.env`-filen, där du ersätter platshållarna `<mail@example.com>`, `<mail@example2.com>`, och `<username/repository>` med dina faktiska värden:

```env
# Email Configuration Parameters
FROM_EMAIL=<mail@example.com>
TO_EMAIL=<mail@example2.com>

# GitHub Repository ID
GITHUB_REPOSITORY_ID=<username/repository>
```


## Steg 3: Skapa `cloudformation.yaml`
Öppna terminalen och skapa en ny fil med följande kommando:

```bash
touch cloudformation.yaml
```

Lägg sedan till följande grundläggande struktur i filen:

```yaml
AWSTemplateFormatVersion: 2010-09-09
Description: |
  Denna CloudFormation-mall provisionerar en **serverlös miljö** för ett kontaktformulär 
  som skickar **bekräftelsemail** till den ansvarige personen.
  
  Webbplatsen är hostad på en **S3-bucket** och nås av användare genom **CloudFront**.
  
  Lösningen använder flera **Lambda-funktioner** för backend-bearbetning, med 
  **GitHub-integration** och **CodePipeline** för att hantera uppdateringar av webbplatsen.

Resources:
  # Här kommer dina AWS-resurser att definieras, exempelvis S3-bucket, Lambda, API Gateway, osv.

```
