@AbapCatalog.viewEnhancementCategory: [ #NONE ]
// Aggregates the point key away, so no row-level condition is possible.
// Returns distinct program / class names only - the same metadata the
// configuration app already shows to anyone allowed to open it.

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Value Help for Maintained Act. Classes'

@Search.searchable: true

define view entity ZI_APG_GATE_ACT_CLASS_VH
  as select from zapg_gate_handle

{
      @EndUserText.label: 'Activation Class'
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @UI.lineItem: [ { position: 10 } ]
  key activation_class as ActivationClass
}

where activation_class is not initial
group by activation_class
