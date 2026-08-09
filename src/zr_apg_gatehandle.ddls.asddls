@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Handlers'
@Search.searchable: true
define view entity ZR_APG_GateHandle
  as select from zapg_gate_handle
  association to parent ZR_APG_Point as _Point on $projection.PointId = _Point.PointId
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
  key point_id              as PointId,

  key seqno                 as SeqNo,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      handler_class         as HandlerClass,

      active                as Active,

      // Criticality: 3 = active (green), 2 = custom toggle (yellow), 1 = inactive (red)
      case active
        when 'X' then 3
        when 'C' then 2
        else 1
      end                   as ActiveCriticality,

      activation_class      as ActivationClass,
      param_1               as Param1,
      param_2               as Param2,

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

      _Point
}
