# Survival-Analysis-on-Machine-Incident-Prediction
Time-to-Failure Prediction using Coxph Regression Model

### Problem statement

Resolving incidents after they have been raised may not be an efficient way in asset-heavy industry as the costs associated with downtime of the assets are high. Predicting the incidents in advance so we can proactively prevent them from occurring will avoid or reduce the costs associated with downtime.

### Goal

To train a model that uses incident history and predicts the probability that an asset will fail in next X (10) days.

### Dataset description

You are provided with 3 data sets:
<br>
Asset Data: This file consists of asset level information. Each asset refers to a printing device
<br>
1. AssetNumericID: Unique ID for the asset
2. AssetID: Unique GUID for the asset
	- ModelName: Manufacture model of the asset
	- ModelClass: Class of an asset (production or Multifunction)
	- IsColor: if asset is a color printer or not
	- PPM: Pages per minute that the asset is capable of printing 
	- IsScanner: if asset has inbuilt scanner or not
	- IsCopier: if asset is a copier or not
	- IsFax: if asset is capable of faxing or not
	- ageInMonths: age of an asset
<br>
Incident Data: This file consists of Incident history for each asset. There might be assets that have no incidents.
<br>
	AssetID: unique GUID for the asset
	DateOccurred: Occurred date of the incident
	ProblemtypeName: Type of an incident
<br>
Volume Data: This file consists of printing history of an Asset
<br>
	AssetID: unique GUID for the asset
	ReadDate: Date and time the volume has been recorded
	Volume: Number of pages that the asset has printed
