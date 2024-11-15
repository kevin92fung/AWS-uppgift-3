# Skapa och deploya projekt med Git och `.env`-fil

Följ dessa steg för att skapa och deploya ditt projekt.

### 1. Skapa en `.env`-fil
För att skapa en `.env`-fil som innehåller de angivna miljövariablerna, öppna en terminal och kör följande kommando för att skapa filen:

```bash
touch .env
```

Öppna sedan `.env`-filen i din favorittextredigerare och lägg till följande innehåll:

```env
# Email Configuration Parameters
FROM_EMAIL=<mail@example.com>
TO_EMAIL=<mail@example2.com>

# GitHub Repository ID
GITHUB_REPOSITORY_ID=<username/repository>
```

Spara och stäng filen.

### 2. Pull Git-repository
För att hämta det senaste innehållet från ditt GitHub-repository, använd följande kommando:

```bash
git pull https://github.com/kevin92fung/aws-uppgift-3.git
```

Detta hämtar koden från GitHub-repositoryt `aws-uppgift-3` till din lokala maskin.

### 3. Navigera till rätt katalog
När du har klonat eller hämtat repositoryt, navigera till den katalog som innehåller projektet genom att köra:

```bash
cd path/to/your/project
```

Ersätt `path/to/your/project` med den faktiska sökvägen till katalogen där projektet är placerat.

### 4. Deploya med deploy-skriptet
När du är i rätt katalog, kör deploy-skriptet för att starta deploymenten:

```bash
./deploy
```

Detta skript kommer att köra de nödvändiga kommandona för att deploya ditt projekt.
