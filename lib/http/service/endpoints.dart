class ApiEndPoints {
  static const String baseUrl = 'http://20.86.117.62:8105/api/v1/';
  
  // Auth
  static const String login = "Auth/login/";
  static const String refreshIndicator = "Auth/refreshtoken";
  static const String resetPassword = "Auth/reset-password/{token}";
  static const String forgotPassword = "Auth/forgot-password";
  static const String logout = "Account/Logout/";

  // Audit/Asset
  static const String AddAssets = "Asset/assets/";
  static const String updateAsset = "Asset/AssetAudit";
  static String getAssetsByBarcode(String barcode) => 
    "/Asset/assets/by-barcode/$barcode";
  
  // Dashboard/Home
  static const String getAllAssetsByLocation = "Asset/GetAllAssetsByLocation";
  static const String getAllAssetsByDateByPerson = "Asset/GetAllAssetsByDateByPerson";
  static const String getAllAssetAuditCountLocation = "Asset/GetAllAssetAuditCountLocation";
  static const String getPersonsByDepartment = "Asset/assets/by-department/{departmentId}"; 
  
  // Company
  static const String getLocationsByUserId = "Config/locations/{id}";
   static const String getLocations = 'Config/locations';

   //gets on capture
    static const String getDepartments = "Config/departments";
    static const String getPlants = "Config/plants";
    static const String getCostCentres = "Config/cost-centres";
    static const String getAssetTypes = "Config/asset-classes";
    static const String getConditions = "Config/conditions";
    static const String getPersons = "Config/persons";

    //home
    static const String getDashboardSummary = "Dashboard/app-dashboard";
    static const String getListofAudits = "Asset/assetAudit-mismatch/pending";
    


}