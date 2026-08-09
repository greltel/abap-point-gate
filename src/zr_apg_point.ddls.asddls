@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Point Header'
@Search.searchable: true
define root view entity ZR_APG_Point
  as select from zapg_point
  composition [0..*] of ZR_APG_GateHandle as _Gates
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
  key point_id              as PointId,

      description           as Description,
      module_name           as ModuleName,
      active                as Active,
      src_main_prog         as SrcMainProg,
      src_include           as SrcInclude,
      src_line              as SrcLine,
      point_type            as PointTypeCode,
      activation_class      as ActivationClass,

      // Criticality: 3 = active (green), 2 = custom toggle (yellow), 1 = inactive (red)
      case active
        when 'X' then 3
        when 'C' then 2
        else 1
      end                   as ActiveCriticality,

      @Semantics.user.createdBy: true
      created_by            as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,

      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      _Gates
}
