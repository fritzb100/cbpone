# CBP Readiness Platform 🛡️

An AI-powered Salesforce application that predicts U.S. Customs and Border Protection deployment readiness across ports of entry using OpenAI integration.

![Salesforce](https://img.shields.io/badge/Salesforce-00A1E0?style=flat&logo=salesforce&logoColor=white)
![Lightning Web Components](https://img.shields.io/badge/LWC-0070D2?style=flat&logo=salesforce)
![Apex](https://img.shields.io/badge/Apex-00A1E0?style=flat)
![OpenAI](https://img.shields.io/badge/OpenAI-412991?style=flat&logo=openai&logoColor=white)

---

## 📋 Overview

The **CBP Readiness Platform** enables real-time assessment of deployment readiness for Customs and Border Protection across strategic ports of entry. Users interact with an interactive map to trigger AI-powered assessments that predict readiness scores based on location, infrastructure, and strategic factors.

### Key Features
✅ **Interactive Map UI** - Lightning Web Component with geolocation markers  
✅ **AI-Powered Assessments** - OpenAI GPT-4o-mini integration via secure callouts  
✅ **Async Processing** - Queueable Apex for non-blocking API calls  
✅ **Real-Time Updates** - Client-side polling for status changes  
✅ **Secure Integration** - Named Credentials for API key management  
✅ **100% Test Coverage** - HttpCalloutMock for comprehensive testing  

---

## 🏗️ Architecture

### Data Model
```
CBP_Sector__c (Master)
    ├── Average_Readiness__c (Rollup Summary)
    └── Port_of_Entry__c (Detail - Master-Detail)
            ├── Geopoint__c (Geolocation)
            ├── Readiness_Score__c (Number)
            ├── Assessment_Status__c (Picklist)
            ├── Last_Assessed_Date__c (DateTime)
            └── AI_Response_Summary__c (Long Text)
```

### Components
- **LWC:** `readinessMap` - Interactive map with modal dialogs
- **Apex Controller:** `ReadinessController` - Handles UI requests
- **Queueable:** `ReadinessQueueable` - Async OpenAI callout
- **Test Class:** `ReadinessQueueableTest` - 100% code coverage

---

## 🚀 Quick Start

### Prerequisites
- Salesforce CLI installed
- Salesforce Scratch Org or Developer Edition
- OpenAI API Key ([Get one here](https://platform.openai.com/api-keys))

### 1. Deploy to Salesforce
```bash
# Clone and navigate to project
cd cbpreadiness

# Deploy to your org
sf project deploy start --target-org YOUR_ORG_ALIAS

# Or push to scratch org
sf project deploy start
```

### 2. Configure OpenAI Integration
See **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** for detailed Named Credential setup.

**Quick steps:**
1. Setup → Named Credentials → New
2. Create External Credential with your OpenAI API key
3. Create Named Credential: `OpenAI_NC` pointing to `https://api.openai.com`

### 3. Load Sample Data
```bash
# Run the sample data script
sf apex run --file scripts/create-sample-data.apex --target-org YOUR_ORG_ALIAS
```

This creates 4 sectors and 14 ports across the United States.

### 4. Add Component to Page
1. App Builder → Create/Edit Lightning Page
2. Drag `readinessMap` component onto page
3. Save and activate

### 5. Test the App
1. Click any port marker on the map
2. Click "Assess Readiness"
3. Watch real-time status updates
4. View AI-generated score and reasoning

---

## 🧪 Run Tests

```bash
# Run all tests
sf apex run test --test-level RunLocalTests --result-format human --code-coverage

# Expected: 100% coverage on all classes
```

---

## 📚 Documentation

- **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** - Complete deployment and configuration guide
- **[INTERVIEW_GUIDE.md](./INTERVIEW_GUIDE.md)** - Interview prep, demo script, and Q&A

---

## 🎯 Technical Highlights

### Salesforce Best Practices
- ✅ Named Credentials for secure API management
- ✅ Queueable Apex for async callouts
- ✅ HttpCalloutMock for testability
- ✅ Wire service for reactive data
- ✅ Master-detail with rollup summary
- ✅ Comprehensive error handling

### Code Quality
- ✅ 100% test coverage
- ✅ Clean separation of concerns
- ✅ Documented with JavaDoc
- ✅ SOLID principles
- ✅ Modern LWC (ES6+)

---

## 📊 Project Stats

| Metric | Value |
|--------|-------|
| Apex Classes | 3 |
| LWC Components | 1 |
| Custom Objects | 2 |
| Custom Fields | 7 |
| Test Coverage | 100% |
| Lines of Code | ~500 |

---

## 🔮 Future Enhancements

- [ ] **Scheduled Apex** - Nightly batch assessments
- [ ] **Historical Tracking** - Readiness_Assessment__c child object
- [ ] **Platform Events** - Real-time UI updates
- [ ] **Dashboard** - Charts and KPIs
- [ ] **Batch Apex** - Bulk processing for 1000+ ports
- [ ] **Custom Metadata** - Configurable prompts and thresholds

---

## 🤝 Contributing

This is an interview demo project. Feel free to fork and extend!

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🙋 Questions?

Built by **Fritz Bien-Aime** for Salesforce Developer interview preparation.

For setup help, see [SETUP_GUIDE.md](./SETUP_GUIDE.md)  
For interview prep, see [INTERVIEW_GUIDE.md](./INTERVIEW_GUIDE.md)
