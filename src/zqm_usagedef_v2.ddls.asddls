@AbapCatalog.sqlViewName: 'ZVQM_USGDEF2'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Usage Definition Quality Portal - v2'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@OData.publish: true

define view ZQM_USAGEDEF_V2
  with parameters
    p_plant : werks_d
  as select from qave as ud
    inner join qals as ql
      on ud.prueflos = ql.prueflos and ql.werk = :p_plant
{
  key ql.werk         as plant,
      ud.prueflos     as inspection_lot,
      ud.vorglfnr     as operation_number,

  case ud.vcode
    when 'A' then 'Accepted'
    when 'R' then 'Rejected'
    when 'S' then 'Rework'
    when 'B' then 'Accepted with Deviation'
    else 'Unknown'
  end as usage_decision_text,

  case ql.art
    when '05' then 'Goods Receipt'
    when '04' then 'Stock Posting'
    when '03' then 'In-Process'
    when '02' then 'After Production'
    else ql.art
  end as inspection_type,

  ql.objnr    as object_number,
  ql.obtyp    as object_type,

  case ql.stat35
    when 'X' then 'Completed'
    else 'Pending'
  end as status,

  ql.selmatnr as material
}
