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