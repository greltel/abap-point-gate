@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #CHECK

@EndUserText.label: 'Value Help for Point ID'

@Search.searchable: true

define view entity ZI_APG_POINT_VH
  as select from zapg_point

{
      @EndUserText.label: 'Point Gate ID'
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @UI.lineItem: [ { position: 10 } ]
  key point_id as PointId
}
