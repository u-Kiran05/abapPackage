@AbapCatalog.sqlViewName: 'ZVQLOGIN2'  
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'QUALITY LOGIN'
@Metadata.ignorePropagatedAnnotations: true
@OData:{
publish:true
}
define view ZPP_QLOGIN_V
    with parameters
    p_bname : xubname,
    p_pass  : zpp_pass_de
  as select from zpp_sflogin
{
  key bname,
  pass,
  cast('Y' as abap.char(1)) as login_status
}
where bname = :p_bname and pass = :p_pass


