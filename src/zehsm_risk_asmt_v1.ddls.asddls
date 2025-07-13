@AbapCatalog.sqlViewName: 'ZV_RISK_ASMT'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'EHSM RISK ASSESSMENT'
@Metadata.ignorePropagatedAnnotations: true
@OData.publish: true
define view ZEHSM_RISK_ASMT_V1   as select from zsv_risk_asmt
{
    key node_id            as NodeID,
        created_on_at      as CreatedOnAt,
        created_by         as CreatedBy,
        changed_by         as ChangedBy,
        risk_key_ref       as RiskKeyRef,
        asmt_team_member   as AsmtTeamMember,
        role               as Role,
        regulation         as Regulation,
        url_link_to_reg    as UrlLinkToReg
}   
