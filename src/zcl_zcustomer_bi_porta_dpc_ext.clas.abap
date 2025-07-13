class ZCL_ZCUSTOMER_BI_PORTA_DPC_EXT definition
  public
  inheriting from ZCL_ZCUSTOMER_BI_PORTA_DPC
  create public .

public section.
protected section.

  methods CUSTOMERDASHBOAR_GET_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZCUSTOMER_BI_PORTA_DPC_EXT IMPLEMENTATION.


method CUSTOMERDASHBOAR_GET_ENTITY.

  DATA: lv_customer_id TYPE kunnr,
        ls_key         TYPE /iwbep/s_mgw_name_value_pair,
        ls_aging       TYPE zsd_caging_t,
        ls_credit      TYPE zsd_ccandd_t,
        ls_debit       TYPE zsd_ccandd_t,
        ls_del_h       TYPE zsd_cdelivery_t,
        ls_del_i       TYPE zsd_cdelivery_i_t,
        ls_inq_h       TYPE zsd_cinquiry_t,
        ls_inq_i       TYPE zsd_cinquiryitem_t,
        ls_inv_h       TYPE zsd_cinvoice_t,
        ls_inv_i       TYPE zsd_cinvoice_i_t,
        ls_sales_h     TYPE zsd_csales_t,
        ls_sales_i     TYPE zsd_csales_i_t.

  " Extract CustomerId from IT_KEY_TAB
  READ TABLE it_key_tab INTO ls_key WITH KEY name = 'ICustomerId'.
  IF sy-subrc = 0.
    lv_customer_id = ls_key-value.
  ENDIF.

  " Call your RFC to get all BI data
  CALL FUNCTION 'ZFM_CBI'
    EXPORTING
      i_customer_id   = lv_customer_id
    IMPORTING
      es_aging        = ls_aging
      es_credit       = ls_credit
      es_debit        = ls_debit
      es_delivery_h   = ls_del_h
      es_delivery_i   = ls_del_i
      es_inquiry_h    = ls_inq_h
      es_inquiry_i    = ls_inq_i
      es_invoice_h    = ls_inv_h
      es_invoice_i    = ls_inv_i
      es_sales_h      = ls_sales_h
      es_sales_i      = ls_sales_i.

  " Serialize each structure to JSON using CL_JSON
  DATA(lo_json) = NEW /ui2/cl_json( ).

  er_entity-I_Customer_Id = lv_customer_id.

  lo_json->serialize( EXPORTING data = ls_aging      RECEIVING r_json = er_entity-EsAging     ).
  lo_json->serialize( EXPORTING data = ls_credit     RECEIVING r_json = er_entity-EsCredit    ).
  lo_json->serialize( EXPORTING data = ls_debit      RECEIVING r_json = er_entity-EsDebit     ).
  lo_json->serialize( EXPORTING data = ls_sales_h    RECEIVING r_json = er_entity-EsSalesH    ).
  lo_json->serialize( EXPORTING data = ls_sales_i    RECEIVING r_json = er_entity-EsSalesI    ).
  lo_json->serialize( EXPORTING data = ls_del_h      RECEIVING r_json = er_entity-EsDeliveryH ).
  lo_json->serialize( EXPORTING data = ls_del_i      RECEIVING r_json = er_entity-EsDeliveryI ).
  lo_json->serialize( EXPORTING data = ls_inv_h      RECEIVING r_json = er_entity-EsInvoiceH  ).
  lo_json->serialize( EXPORTING data = ls_inv_i      RECEIVING r_json = er_entity-EsInvoiceI  ).
  lo_json->serialize( EXPORTING data = ls_inq_h      RECEIVING r_json = er_entity-EsInquiryH  ).
  lo_json->serialize( EXPORTING data = ls_inq_i      RECEIVING r_json = er_entity-EsInquiryI  ).

ENDMETHOD.
ENDCLASS.
