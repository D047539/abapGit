CLASS zcl_abapgit_object_chko DEFINITION
  PUBLIC
  INHERITING FROM zcl_abapgit_objects_super
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_abapgit_object.
    ALIASES mo_files FOR zif_abapgit_object~mo_files.
  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_content,
        category           TYPE string,
        implementing_class TYPE string,
        remote_enabled     TYPE flag,
        parameters         TYPE cl_chko_db_api=>ty_parameters,
      END OF ty_content .
    TYPES:
      BEGIN OF ty_chko.
        INCLUDE TYPE if_aff_types=>ty_aff_header.
    TYPES:
        content TYPE ty_content,
      END OF ty_chko .
ENDCLASS.



CLASS zcl_abapgit_object_chko IMPLEMENTATION.


  METHOD zif_abapgit_object~changed_by.
    DATA(chko_db_api) = NEW cl_chko_db_api( ).
    DATA(chko_header) = chko_db_api->get_header( name     = CONV #( ms_item-obj_name )
                                                 version  = 'I' ).
    IF chko_header IS INITIAL.
      chko_header = chko_db_api->get_header( name     = CONV #( ms_item-obj_name )
                                                   version  = 'A' ).
    ENDIF.
    rv_user = chko_header-changed_by.
  ENDMETHOD.


  METHOD zif_abapgit_object~delete.
    DATA(chko_db_api) = NEW cl_chko_db_api( ).
    chko_db_api->delete(
      name    = CONV #( ms_item-obj_name )
      version = 'I'
    ).
    chko_db_api->delete(
      name    = CONV #( ms_item-obj_name )
      version = 'A'
    ).
  ENDMETHOD.


  METHOD zif_abapgit_object~deserialize.
    " test with simple type
types:
      BEGIN OF ty_main,
      format_version     TYPE if_aff_types_v1=>ty_format_version,
      header             TYPE if_aff_types_v1=>ty_header_60,
      category           TYPE if_aff_types_v1=>ty_object_name_30,
      implementing_class TYPE if_aff_types_v1=>ty_object_name_30,
      remote_enabled     TYPE abap_bool,
*      parameters         TYPE ty_parameters,
      END OF ty_main.

    data properties type ty_main.

*    data properties type if_aff_chko_v1=>ty_main.

    DATA(json_as_xstring) = mo_files->read_raw( iv_ext = 'json' ) ##NO_TEXT.

    TRY.
        NEW zcl_abapgit_ajson_cnt_handler( )->deserialize( EXPORTING content = json_as_xstring IMPORTING data = properties ).
        properties-header-abap_language_version = if_abap_language_version=>gc_version-sap_cloud_platform.

        DATA(persistence) = NEW lcl_chko_aff_persistence( ).
        persistence->save_content(
          data     = properties
          object   = NEW cl_aff_obj( package = ms_item-devclass name = CONV #( ms_item-obj_name ) type = ms_item-obj_type )
          language = mv_language
          version  = 'I'
          saved_by = sy-uname ).
      CATCH cx_aff_root INTO DATA(exception).
        ii_log->add_exception(
            ix_exc  = exception
            is_item = ms_item ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_abapgit_object~exists.
    rv_bool = NEW cl_chko_db_api( )->exists( name = CONV #( ms_item-obj_name ) ).
  ENDMETHOD.


  METHOD zif_abapgit_object~get_comparator.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_object~get_deserialize_steps.
    APPEND zif_abapgit_object=>gc_step_id-abap TO rt_steps.
  ENDMETHOD.


  METHOD zif_abapgit_object~get_metadata.
    rs_metadata = get_metadata( ).
  ENDMETHOD.


  METHOD zif_abapgit_object~is_active.
    rv_active = is_active( ).
  ENDMETHOD.


  METHOD zif_abapgit_object~is_locked.
    DATA(lock_object) = |{ ms_item-obj_type }{ ms_item-obj_name }*|.

    rv_is_locked = exists_a_lock_entry_for( iv_lock_object = 'ESWB_EO'
                                            iv_argument    = CONV #( lock_object ) ).
  ENDMETHOD.


  METHOD zif_abapgit_object~jump.
  ENDMETHOD.


  METHOD zif_abapgit_object~serialize.
    DATA hex TYPE xstring.

    TRY.
        DATA properties TYPE if_aff_chko_v1=>ty_main.
        DATA(persistence) = NEW lcl_chko_aff_persistence( ).
        persistence->get_content(
          EXPORTING
            object   = NEW cl_aff_obj( package = ms_item-devclass name = CONV #( ms_item-obj_name ) type = ms_item-obj_type )
            language = mv_language
            version  = 'A'
          IMPORTING
            data     = properties ).


        hex = NEW zcl_abapgit_ajson_cnt_handler( )->serialize( data = properties ).
        mo_files->add_raw( iv_ext = 'json' iv_data = hex ).

      CATCH cx_aff_root INTO DATA(exception).
*        ii_log->add_exception(
*          ix_exc  = exception
*          is_item = ms_item ).
      CATCH zcx_abapgit_ajson_error INTO DATA(exception_ajson).
*        ii_log->add_exception(
*         ix_exc  = exception_ajson
*         is_item = ms_item ).
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
