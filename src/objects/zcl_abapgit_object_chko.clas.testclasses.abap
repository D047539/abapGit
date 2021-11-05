class ltcl_chko definition final for testing
  duration short
  risk level harmless.

  private section.
    class-data:
      environment type ref to if_osql_test_environment.
    class-methods:
      class_setup,
      class_teardown.

    data:
      cut type ref to zif_abapgit_object.
    methods:
      setup,
      insert_chko_in_db importing name type wb_object_name,
      get_chko_as_json returning value(result) type rswsourcet,
      get_chko_as_json_no_params returning value(result) type rswsourcet,
      serialize for testing raising cx_static_check,
*      deserialize_chko_w_params for testing raising cx_static_check,
      deserialize_chko_wo_params for testing raising cx_static_check.
endclass.


class ltcl_chko implementation.

  method class_setup.
    environment = cl_osql_test_environment=>create( i_dependency_list = value #(
      ( 'TADIR' )
      ( 'CHKO_HEADER' )
      ( 'CHKO_HEADERT' )
      ( 'CHKO_CONTENT' )
      ( 'CHKO_PARAMETER' )
      ( 'CHKO_PARAMETERST' )
     ) ).
  endmethod.

  method class_teardown.
    if environment is bound.
      environment->destroy( ).
    endif.
  endmethod.

  method setup.
    data(item) = value zif_abapgit_definitions=>ty_item(
      obj_name = 'CHKO_TEST'
      obj_type = 'CHKO'
      devclass = '$TMP' ).
    cut = new zcl_abapgit_object_chko( iv_language = sy-langu
                                      is_item = item ).
    cut->mo_files = new zcl_abapgit_objects_files( is_item = item ).
    environment->clear_doubles( ).
  endmethod.

  method serialize.
    insert_chko_in_db( 'CHKO_TEST' ).
    cut->serialize(
      io_xml = new zcl_abapgit_xml_output( ) ).
*      ii_log = new zcl_abapgit_log( ) ).

    data(act_files) = cut->mo_files->get_files( ).

    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( act_files ) ).
    data(json) = cl_abap_codepage=>convert_from( act_files[ 1 ]-data ).
  endmethod.

  method deserialize_chko_wo_params.
    data(json_table) = get_chko_as_json_no_params( ).
    concatenate lines of json_table into data(json).
    data(json_as_xstring) = zcl_abapgit_convert=>string_to_xstring_utf8( json ).

    cut->mo_files->add_raw( iv_ext = 'json' iv_data = json_as_xstring ).

    cut->deserialize(
      iv_package = '$TMP'
      io_xml     = value #( )
      iv_step    = zif_abapgit_object=>gc_step_id-abap
      ii_log     = new zcl_abapgit_log( ) ).

    select from chko_header fields * into table @data(header).
    break-point.
  endmethod.

*  method deserialize_chko_w_params.
*    data(json_table) = get_chko_as_json( ).
*    concatenate lines of json_table into data(json).
*    data(json_as_xstring) = zcl_abapgit_convert=>string_to_xstring_utf8( json ).
*
*    cut->mo_files->add_raw( iv_ext = 'json' iv_data = json_as_xstring ).
*
*    cut->deserialize(
*      iv_package = '$TMP'
*      io_xml     = value #( )
*      iv_step    = zif_abapgit_object=>gc_step_id-abap
*      ii_log     = new zcl_abapgit_log( ) ).
*
*    select from chko_header fields * into table @data(header).
*    break-point.
*  endmethod.

  method insert_chko_in_db.
    data chko_header type table of chko_header.
    chko_header = value #(
      ( name = name version = 'A' abap_language_version = if_abap_language_version=>gc_version-sap_cloud_platform )
    ).
    environment->insert_test_data( chko_header ).

    data chko_headert type table of chko_headert.
    chko_headert = value #(
      ( name = name version = 'A' spras = sy-langu description = 'Test description' )
    ).
    environment->insert_test_data( chko_headert ).

    data chko_content type table of chko_content.
    chko_content = value #(
      ( name = name version = 'A' category = 'TEST_CATEGORY' implementing_class = 'TEST_CLASS' remote_enabled = abap_true )
    ).
    environment->insert_test_data( chko_content ).

    data chko_parameter type table of chko_parameter.
    chko_parameter = value #(
      ( chko_name = name version = 'A' technical_id = 1 name = 'parameter' modifiable = abap_true )
    ).
    environment->insert_test_data( chko_parameter ).

    data chko_parameterst type table of chko_parameterst.
    chko_parameterst = value #(
      ( chko_name = name version = 'A' technical_id = 1 spras = sy-langu description = 'Parameter description' )
    ).
    environment->insert_test_data( chko_parameterst ).

    data tadir type table of tadir.
    tadir = value #(
      ( pgmid = 'R3TR' object = 'CHKO' obj_name = name masterlang = 'E' )
    ).
    environment->insert_test_data( tadir ).
  endmethod.

  method get_chko_as_json.
    result = value #(
( `{` )
( `  "formatVersion": "1",` )
( `  "header": {` )
( `    "description": "Test description",` )
( `    "originalLanguage": "EN"` )
( `  },` )
( `  "category": "TEST_CATEGORY",` )
( `  "implementingClass": "TEST_CLASS",` )
( `  "parameters": [` )
( `    {` )
( `      "technicalId": "1",` )
( `      "name": "parameter",` )
( `      "description": "Parameter description",` )
( `      "hidden": true` )
( `    }` )
( `  ]` )
( `}` ) ).
  endmethod.

  method get_chko_as_json_no_params.
    result = value #(
( `{` )
( `  "formatVersion": "1",` )
( `  "header": {` )
( `    "description": "Test description",` )
( `    "originalLanguage": "EN"` )
( `  },` )
( `  "category": "TEST_CATEGORY",` )
( `  "implementingClass": "TEST_CLASS"` )
( `}` ) ).
  endmethod.

endclass.
