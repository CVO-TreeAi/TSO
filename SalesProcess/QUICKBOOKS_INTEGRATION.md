# TreeShop QuickBooks Integration Guide

## 🎯 AUTOMATED PROPOSAL TO QUICKBOOKS WORKFLOW

### Complete Integration Setup

1. **Line Item Codes** (One-time setup in QuickBooks)
2. **Service Templates** (Pre-configured estimates)
3. **API Integration** (Automated sync)
4. **Mobile App Connection** (Real-time updates)

---

## 📊 QUICKBOOKS LINE ITEM SETUP

### Service Item Codes

```
TREE-REM-S    Tree Removal - Small (<30ft)
TREE-REM-M    Tree Removal - Medium (30-60ft)
TREE-REM-L    Tree Removal - Large (60-80ft)
TREE-REM-XL   Tree Removal - Giant (>80ft)

TRIM-05       Tree Trimming - Light (5-10%)
TRIM-15       Tree Trimming - Moderate (10-20%)
TRIM-25       Tree Trimming - Heavy (20-30%)
TRIM-40       Tree Trimming - Severe (30%+)

STUMP-S       Stump Grinding - Small (<12")
STUMP-M       Stump Grinding - Medium (12-24")
STUMP-L       Stump Grinding - Large (24-36")
STUMP-XL      Stump Grinding - Giant (36"+)

MULCH-1       Forestry Mulching - 1 Acre
MULCH-2       Forestry Mulching - 2-5 Acres
MULCH-5       Forestry Mulching - 5+ Acres

EMRG-1        Emergency - Priority 1 (Critical)
EMRG-2        Emergency - Priority 2 (High)
EMRG-3        Emergency - Priority 3 (Moderate)

LAND-CLR      Land Clearing - Per Day
CRANE-HR      Crane Service - Per Hour
ASSESS        Tree Assessment - Per Tree
WOOD-RET      Wood Retention - Processing
ROW-CLR       Right-of-Way - Linear Foot
```

### Custom Fields Configuration

```
TreeScore     Number field for point calculation
AFISS         Number field for multiplier
Hours_Est     Number field for estimated hours
Crew_Size     Number field for crew count
Equipment     Text field for equipment list
```

---

## 🔄 IMPORT TEMPLATES

### CSV Import Format

```csv
*Name,*Type,Description,Rate,Income Account,QTY,Tax
TREE-REM-S,Service,"Tree Removal Small (<30ft)",0,"Tree Services",TS,TAX
TREE-REM-M,Service,"Tree Removal Medium (30-60ft)",0,"Tree Services",TS,TAX
TREE-REM-L,Service,"Tree Removal Large (60-80ft)",0,"Tree Services",TS,TAX
```

### Bulk Import Instructions

1. **Prepare CSV** with all service codes
2. **Navigate to** Lists → Item List
3. **Select** Import → Items
4. **Map fields** to QuickBooks fields
5. **Verify** import preview
6. **Complete** import process

---

## 💻 API INTEGRATION

### Connection Setup

```javascript
// QuickBooks API Configuration
const QBConfig = {
  clientId: 'YOUR_CLIENT_ID',
  clientSecret: 'YOUR_CLIENT_SECRET',
  environment: 'production',
  redirectUri: 'https://treeshop.app/callback'
};

// Estimate Creation
async function createEstimate(proposal) {
  const estimate = {
    DocNumber: `EST-${Date.now()}`,
    TxnDate: proposal.date,
    CustomerRef: {
      value: proposal.customerId
    },
    Line: proposal.services.map(service => ({
      DetailType: "SalesItemLineDetail",
      Amount: service.price,
      SalesItemLineDetail: {
        ItemRef: {
          value: service.itemCode,
          name: service.description
        },
        Qty: service.treeScore,
        UnitPrice: service.rate
      }
    })),
    CustomField: [{
      DefinitionId: "1",
      Name: "TreeScore",
      Type: "StringType",
      StringValue: proposal.totalTreeScore
    }]
  };

  return await qbo.createEstimate(estimate);
}
```

---

## 📱 MOBILE SYNC WORKFLOW

### Real-time Proposal to QuickBooks

1. **Field Assessment** → iOS App
2. **TreeScore Calculation** → Automatic
3. **Package Selection** → Customer Choice
4. **Proposal Generation** → Instant
5. **QuickBooks Sync** → One-Click
6. **Customer Signature** → Digital
7. **Invoice Creation** → Automatic

---

## 🎛️ QUICKBOOKS DESKTOP SETUP

### Custom Estimate Template

```
TREESHOP PROFESSIONAL ESTIMATE

Header Fields:
- Company Logo
- License & Insurance Numbers
- ISA Certification

Line Item Columns:
- Service Code
- Description
- TreeScore/Qty
- Rate
- Amount

Footer Fields:
- Terms & Conditions
- Valid Days
- Signature Lines
```

### Memorized Transactions

Create memorized transactions for common services:

```
Name: "Standard Tree Removal"
Items: TREE-REM-M, STUMP-M
Frequency: Don't Remind Me
Next Date: [blank]
```

---

## 🔗 WORKFLOW AUTOMATION

### Zapier/Make.com Integration

**Trigger**: New proposal in TreeShop App
**Actions**:
1. Create/Find customer in QuickBooks
2. Create estimate with line items
3. Send estimate to customer
4. Update CRM with estimate number
5. Schedule follow-up task

### Sample Automation Code

```python
# Webhook receiver for iOS app
@app.route('/webhook/proposal', methods=['POST'])
def handle_proposal():
    data = request.json

    # Map TreeShop to QuickBooks
    qb_estimate = {
        'customer': find_or_create_customer(data['customer']),
        'items': map_services_to_items(data['services']),
        'custom_fields': {
            'TreeScore': data['tree_score'],
            'AFISS': data['afiss_multiplier']
        }
    }

    # Create in QuickBooks
    estimate_id = quickbooks.create_estimate(qb_estimate)

    # Send to customer
    send_estimate_email(estimate_id, data['customer']['email'])

    return {'success': True, 'estimate_id': estimate_id}
```

---

## 📈 REPORTING SETUP

### Key Reports Configuration

1. **Service Performance Report**
   - Group by: Service Item
   - Columns: Quantity (TreeScore), Revenue, Margin
   - Period: Monthly/Quarterly

2. **TreeScore Analysis**
   - Custom report using TreeScore field
   - Average score per job
   - Score to revenue correlation

3. **Crew Efficiency Report**
   - Estimated vs Actual hours
   - Points per hour by crew
   - Equipment utilization

### Dashboard Metrics

```
Today's Stats:
- Estimates Sent: X
- Total TreeScore: XXX
- Conversion Rate: X%
- Average Ticket: $X,XXX

This Month:
- Services Completed: XX
- Total Revenue: $XX,XXX
- Top Service: Tree Removal (45%)
- Average AFISS: 1.3x
```

---

## 🚀 QUICK START CHECKLIST

### Day 1 - Basic Setup
```
□ Import service items CSV
□ Create custom fields
□ Set up estimate template
□ Configure tax settings
□ Test create one estimate
```

### Week 1 - Integration
```
□ Connect iOS app to QuickBooks
□ Map all service codes
□ Test proposal sync
□ Train field staff
□ Create first 10 estimates
```

### Month 1 - Optimization
```
□ Review pricing accuracy
□ Adjust service codes as needed
□ Set up automated workflows
□ Create standard reports
□ Implement follow-up sequences
```

---

## 🔧 TROUBLESHOOTING

### Common Issues & Solutions

**Issue**: TreeScore not showing in QuickBooks
**Solution**: Ensure custom field is created and mapped

**Issue**: Prices not calculating correctly
**Solution**: Check rate × quantity formula in template

**Issue**: Sync failing from iOS app
**Solution**: Verify API credentials and permissions

**Issue**: Duplicate estimates created
**Solution**: Implement idempotency key in webhook

---

## 💡 PRO TIPS

1. **Batch Operations**: Import multiple estimates at once
2. **Templates**: Create templates for common job types
3. **Classes**: Use classes to track by service area
4. **Jobs**: Track multi-service projects as jobs
5. **Recurring**: Set up recurring for maintenance contracts

---

## 📞 SUPPORT RESOURCES

- QuickBooks Support: 1-800-446-8848
- API Documentation: developer.intuit.com
- TreeShop Integration: support@treeshop.app
- Training Videos: treeshop.app/quickbooks

---

This integration enables:
- **5-minute** proposal to invoice workflow
- **100% accurate** pricing based on TreeScore
- **Real-time** sync between field and office
- **Automated** follow-ups and reminders
- **Complete** financial tracking and reporting