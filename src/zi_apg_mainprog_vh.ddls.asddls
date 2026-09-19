@AbapCatalog.viewEnhancementCategory: [ #NONE ]
// Aggregates the point key away, so no row-level condition is possible.
// Returns distinct program / class names only - the same metadata the
// configuration app already shows to anyone allowed to open it.
@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Value Help for Main Program'

@Search.searchable: true

define view entity ZI_APG_MAINPROG_VH
  as select from zapg_point

{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @UI.lineItem: [ { position: 10 } ]
  key src_main_prog as SrcMainProg
}

where src_main_prog is not initial
group by src_main_prog
