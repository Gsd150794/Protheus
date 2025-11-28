/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1 e mudanca para D_E_L_E_T_ = ' '
Lucas Borges  |24/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
===========================================================================================================================================================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
===========================================================================================================================================================================================================================================================
Vandelei - Alex Wallauer - 16/05/25 - 02/09/25 -  50481  - Controle de entregas redirecionadas para operador logístico. 
Jerry    - Alex Wallauer - 15/08/25 - 02/09/25 -  51229  - Colocado o envio de email para o comercial por nota e por ocorrencias de uma carga.
Jerry    - Alex Wallauer - 20/08/25 - 01/08/25 -  49733  - Colocado campos visuais na capa: F2_I_PENCL, C5_I_AGEND , F2_I_OPER, F2_I_OPLO, F2_I_REDP e F2_I_RELO.
Jerry    - Jose Gavetti  - 08/10/25 - 10/10/25 -  52364  - Inserido campo C5_I_CDUSU para ser enviado no cabeçalho do Pedido.
Vandelei - Alex Wallauer - 10/10/25 - 13/10/25 -  52438  - Colocado o botão de ""Monitor Integração" na rotina de ocorrências de frete.
Jerry    - Julio Paz     - 30/10/25 - 05/11/25 -  52527  - Alterar a rotina para enviar e-mails também para o Supervisor do Vendedor.
===========================================================================================================================================================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FwMVCDef.ch"
#Include "RWMAKE.CH"
#Include "TopConn.ch"
#Include "ap5mail.ch"

Static _aItOcorre := {}    As Array
Static _lMOMS016  := .F.   As Logical
Static _lEmail    := .F.
Static _lJob      := IsBlind()
Static _aDadosEmailCom:={} As Array

/*
===============================================================================================================================
Programa--------: AOMS003
Autor-----------: Josué Danich Prestes
Data da Criacao-: 18/04/2016
Descrição-------: Cadastro de ocorrências de frete - Chamado 15345
Parametros------: cFilter - Quando chamado de um botão "Ocorrências de frete"
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS003(cFilter As char)

 Private _oBrowse := Nil As Object
 Private _lUsaMVC := .T. As Logical
 Private _cNomeFonte := "AOMS003" As Char
 Private _lEnviou := .F. As Logical
 Public _cRetorno := "   " As Char
 Default cFilter  := ""

 _lMOMS016 := FWIsInCallStack("U_MOMS016") .Or. FWIsInCallStack("SPEDNFE")

 // Configura e inicializa a Classe do Browse
 _oBrowse := FWMBrowse():New()

 _oBrowse:SetAlias( "ZF5" )
 _oBrowse:SetMenuDef( 'AOMS003' )
 _oBrowse:SetDescription( "Ocorrências de frete" )

 // Montagem das legendas
 _oBrowse:AddLegend('Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_STATUS")=="P"',"GREEN", "Pendente" )
 _oBrowse:AddLegend('Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_STATUS")=="E"',"RED",   "Efetivado" )
 _oBrowse:AddLegend('Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_STATUS")=="N"',"GRAY",  "Não Procede" )
 _oBrowse:AddLegend('Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_STATUS")=="T"',"YELLOW","Em tratamento" )

 If !Empty(cFilter)
    _oBrowse:SetFilterDefault( cFilter )
 EndIf

 _oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa--------: MenuDef
Autor-----------: Josué Danich Prestes
Data da Criacao-: 13/04/2016
Descrição-------: Rotina de definição automática do menu via MVC
Parametros------: Nenhum
Retorno---------: aRotina - Definições do menu principal da Rotina.
===============================================================================================================================
*/
Static Function MenuDef()
 Local _aRot := {}

 If !_lMOMS016
    //ADICIONANDO OPÇÕES
    ADD OPTION _aRot TITLE 'Visualizar'            ACTION 'VIEWDEF.AOMS003'                             OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 2
    ADD OPTION _aRot TITLE 'Legenda'               ACTION 'U_AOMS003H'                                  OPERATION 6                      ACCESS 0 //OPERATION 6
    ADD OPTION _aRot TITLE 'Incluir'               ACTION 'VIEWDEF.AOMS003'                             OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
    ADD OPTION _aRot TITLE 'Incl.por Carga'        ACTION 'U_AOMS072'                                   OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
    ADD OPTION _aRot TITLE 'Alterar'               ACTION 'VIEWDEF.AOMS003' 	                          OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
    // Solicitado para retirar o botão excluir por Vanderlei dia 22/08/2025 as 15:40 - chamado: 49733
    // ADD OPTION _aRot TITLE 'Excluir'            ACTION 'VIEWDEF.AOMS003' 	                          OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5 
    ADD OPTION _aRot TITLE 'Imprimir capa'         ACTION 'U_ROMS041'                                   OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
    ADD OPTION _aRot TITLE 'Imprimir NDT'          ACTION 'U_ROMS055I'                                  OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
    ADD OPTION _aRot TITLE 'Aviso Devolução'       ACTION 'U_AOMS003J(ZF5->ZF5_DOCOC,ZF5->ZF5_SEROC)'   OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
    ADD OPTION _aRot TITLE 'Canhoto'               ACTION 'U_VISCANHO(ZF5->ZF5_FILIAL, ZF5->ZF5_DOCOC)' OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
    ADD OPTION _aRot TITLE 'Encerra Multip'        ACTION 'U_AOMS03M(.F.)'                              OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
    ADD OPTION _aRot TITLE "Atualiza Telefones"    ACTION 'U_AOMS03M(.T.)'                              OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
    ADD OPTION _aRot TITLE "Monitor Integração"    ACTION 'U_AOMS081(   )'                              OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 2
 Else
    ADD OPTION _aRot TITLE 'Visualizar'            ACTION 'VIEWDEF.AOMS003'                             OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 2
    ADD OPTION _aRot TITLE 'Legenda'               ACTION 'U_AOMS003H'                                  OPERATION 6                      ACCESS 0 //OPERATION 6
 EndIf

Return _aRot

/*
===============================================================================================================================
Programa--------: ModelDef
Autor-----------: Josué Danich Prestes
Data da Criacao-: 13/04/2016
Descrição-------: Rotina de definição do Modelo de Dados do MVC
Parametros------: Nenhum
Retorno---------: oModel - Objeto do modelo de dados do MVC
===============================================================================================================================
*/
Static Function ModelDef()

 // Inicializa a estrutura do modelo de dados
 Local _oStrCAB	:= FWFormStruct( 1 , "ZF5" , {|_cCampo| AOMS003CPO( _cCampo , 1 ) } ) As Object
 Local _oStrITN	:= FWFormStruct( 1 , "ZF5" , {|_cCampo| AOMS003CPO( _cCampo , 2 ) } ) As Object
 Local _oModel	   As Object
 Local _bValid	   As Block
 Local _bLinePre  As Block
 Local _bLinePost As Block
 Local _bCommit   As Block

 _oStrCAB:AddField( ;
        '' , ;                      // [01] C Titulo do campo                                                 //cTitulo	 Caracteres	Titulo do campo	    X
        "F2_I_PENCL",;              // [02] C ToolTip do campo                                                //cTooltip Caracteres	Tooltip do campo    X
        "F2_I_PENCL",;              // [03] C identificador (ID) do Field                                     //cIdField Caracteres	Id do Field	        X
        'D' , ;                     // [04] C Tipo do campo                                                   //cTipo	 Caracteres	Tipo do campo	    X
        08  , ;                     // [05] N Tamanho do campo                                                //nTamanho Numérico	Tamanho do campo    X
        0   , ;                     // [06] N Decimal do campo                                                //nDecimal Numérico	Decimal do campo    0
        NIL , ;                     // [07] B Code-block de validação do campo                                //bValid	 CodeBlock  Bloco de código de validação do campo {|| .T.}
        NIL , ;                     // [08] B Code-block de validação When do campo                           //bWhen    CodeBlock	Bloco de código de validação when do campo
        NIL , ;                     // [09] A Lista de valores permitido do campo                             //aValues	 Array     Lista de valores permitido do campo	{}
        NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório                 //lObrigat Lógico    Indica se o campo tem preenchimento obrigatório	.F.
        {||IIf(INCLUI,CTOD(""),Posicione("SF2",1,xFilial("SF2")+AllTrim(ZF5->ZF5_DOCOC+ZF5->ZF5_SEROC),"F2_I_PENCL")) } , ;// [11] B Code-block de inicializacao do campo//bInit	 CodeBlock	Bloco de código de inicialização do campo
        NIL , ;                     // [12] L Indica se trata de um campo chave                               //lKey	    Lógico    Indica se trata-se de um campo chave X
        .F. , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update. //lNoUpd   Lógico    Indica se o campo não pode receber valor em uma operação de update	.F.
        .T. )                       // [14] L Indica se o campo é virtual                                     //lVirtual Lógico    Indica se o campo é virtual	.F.
 
 _aGatAux := FwStruTrigger( 'ZF5_DOCOC','F2_I_PENCL','SF2->F2_I_PENCL',.T.,'SF2',1,'xFilial("SF2")+AllTrim(M->ZF5_DOCOC+M->ZF5_SEROC)')
 _oStrCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )
 
 _oStrCAB:AddField( ;
        '' , ;                      // [01] C Titulo do campo                                                 //cTitulo	 Caracteres	Titulo do campo	    X
        "C5_I_AGEND",;              // [02] C ToolTip do campo                                                //cTooltip Caracteres	Tooltip do campo    X
        "C5_I_AGEND",;              // [03] C identificador (ID) do Field                                     //cIdField Caracteres	Id do Field	        X
        'C' , ;                     // [04] C Tipo do campo                                                   //cTipo	 Caracteres	Tipo do campo	    X
        030 , ;                     // [05] N Tamanho do campo                                                //nTamanho Numérico	Tamanho do campo    X
        0   , ;                     // [06] N Decimal do campo                                                //nDecimal Numérico	Decimal do campo    0
        NIL , ;                     // [07] B Code-block de validação do campo                                //bValid	 CodeBlock  Bloco de código de validação do campo {|| .T.}
        NIL , ;                     // [08] B Code-block de validação When do campo                           //bWhen    CodeBlock	Bloco de código de validação when do campo
        NIL , ;                     // [09] A Lista de valores permitido do campo                             //aValues	 Array     Lista de valores permitido do campo	{}
        NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório                 //lObrigat Lógico    Indica se o campo tem preenchimento obrigatório	.F.
        {||If(INCLUI,"",Posicione("SC5",,xFilial("SC5")+ZF5->ZF5_DOCOC,"C5_I_AGEND","IT_NOTA")+" - "+U_TipoEntrega(SC5->C5_I_AGEND) ) },;// [11] B Code-block de inicializacao do campo//bInit	 CodeBlock	Bloco de código de inicialização do campo
        NIL , ;                     // [12] L Indica se trata de um campo chave                               //lKey	    Lógico    Indica se trata-se de um campo chave X
        .F. , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update. //lNoUpd   Lógico    Indica se o campo não pode receber valor em uma operação de update	.F.
        .T. )                       // [14] L Indica se o campo é virtual                                     //lVirtual Lógico    Indica se o campo é virtual	.F.

 _aGatAux := FwStruTrigger( 'ZF5_DOCOC','C5_I_AGEND', 'Posicione("SC5",,xFilial("ZF5")+M->ZF5_DOCOC,"C5_I_AGEND","IT_NOTA")+" - "+U_TipoEntrega(SC5->C5_I_AGEND)', .F. )
 _oStrCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )
 
 _bRelaca1:= {|| If(INCLUI," ", (Posicione("SF2",1,xFilial("SF2")+AllTrim(ZF5->ZF5_DOCOC+ZF5->ZF5_SEROC),"F2_I_OPER"))+" - "+SF2->F2_I_OPLO+" - "+AllTrim(Posicione("SA2",1,xFilial("SA2")+SF2->F2_I_OPER+SF2->F2_I_OPLO,"A2_NOME"))  )}
 
 _oStrCAB:AddField( ;
        '' , ;                      // [01] C Titulo do campo                                                 //cTitulo	 Caracteres	Titulo do campo	    X
        "F2_I_OPER",;               // [02] C ToolTip do campo                                                //cTooltip Caracteres	Tooltip do campo    X
        "F2_I_OPER",;               // [03] C identificador (ID) do Field                                     //cIdField Caracteres	Id do Field	        X
        'C' , ;                     // [04] C Tipo do campo                                                   //cTipo	 Caracteres	Tipo do campo	    X
        100 , ;                     // [05] N Tamanho do campo                                                //nTamanho Numérico	Tamanho do campo    X
        0   , ;                     // [06] N Decimal do campo                                                //nDecimal Numérico	Decimal do campo    0
        NIL , ;                     // [07] B Code-block de validação do campo                                //bValid	 CodeBlock  Bloco de código de validação do campo {|| .T.}
        NIL , ;                     // [08] B Code-block de validação When do campo                           //bWhen    CodeBlock	Bloco de código de validação when do campo
        NIL , ;                     // [09] A Lista de valores permitido do campo                             //aValues	 Array     Lista de valores permitido do campo	{}
        NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório                 //lObrigat Lógico    Indica se o campo tem preenchimento obrigatório	.F.
        _bRelaca1,;                 // [11] B Code-block de inicializacao do campo                            //bInit CodeBlock Bloco de código de inicialização do campo
        NIL , ;                     // [12] L Indica se trata de um campo chave                               //lKey	    Lógico    Indica se trata-se de um campo chave X
        .F. , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update. //lNoUpd   Lógico    Indica se o campo não pode receber valor em uma operação de update	.F.
        .T. )                       // [14] L Indica se o campo é virtual                                     //lVirtual Lógico    Indica se o campo é virtual	.F.

 _cGatilho1:='Posicione("SF2",1,xFilial("SF2")+M->ZF5_DOCOC+M->ZF5_SEROC,"F2_I_OPER")+" -  "+SF2->F2_I_OPLO+" - "+AllTrim(Posicione("SA2",1,xFilial("SA2")+SF2->F2_I_OPER+SF2->F2_I_OPLO,"A2_NOME"))'
 _aGatAux := FwStruTrigger( 'ZF5_DOCOC','F2_I_OPER', _cGatilho1 , .F. )
 _oStrCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )
  
 _bRelacao2:={|| If(INCLUI," ", (Posicione("SF2",1,xFilial("SF2")+AllTrim(ZF5->ZF5_DOCOC+ZF5->ZF5_SEROC),"F2_I_REDP"))+" - "+SF2->F2_I_RELO+" - "+AllTrim(Posicione("SA2",1,xFilial("SA2")+SF2->F2_I_REDP+SF2->F2_I_RELO,"A2_NOME"))  )}
 
 _oStrCAB:AddField( ;
        '' , ;                      // [01] C Titulo do campo                                                 //cTitulo	 Caracteres	Titulo do campo	    X
        "F2_I_REDP",;               // [02] C ToolTip do campo                                                //cTooltip Caracteres	Tooltip do campo    X
        "F2_I_REDP",;               // [03] C identificador (ID) do Field                                     //cIdField Caracteres	Id do Field	        X
        'C' , ;                     // [04] C Tipo do campo                                                   //cTipo	 Caracteres	Tipo do campo	    X
        100 , ;                     // [05] N Tamanho do campo                                                //nTamanho Numérico	Tamanho do campo    X
        0   , ;                     // [06] N Decimal do campo                                                //nDecimal Numérico	Decimal do campo    0
        NIL , ;                     // [07] B Code-block de validação do campo                                //bValid	 CodeBlock  Bloco de código de validação do campo {|| .T.}
        NIL , ;                     // [08] B Code-block de validação When do campo                           //bWhen    CodeBlock	Bloco de código de validação when do campo
        NIL , ;                     // [09] A Lista de valores permitido do campo                             //aValues	 Array     Lista de valores permitido do campo	{}
        NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório                 //lObrigat Lógico    Indica se o campo tem preenchimento obrigatório	.F.
        _bRelacao2,;                // [11] B Code-block de inicializacao do campo                            //bInit CodeBlock Bloco de código de inicialização do campo
        NIL , ;                     // [12] L Indica se trata de um campo chave                               //lKey	    Lógico    Indica se trata-se de um campo chave X
        .F. , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update. //lNoUpd   Lógico    Indica se o campo não pode receber valor em uma operação de update	.F.
        .T. )                       // [14] L Indica se o campo é virtual                                     //lVirtual Lógico    Indica se o campo é virtual	.F.

 _cGatilho2:='(Posicione("SF2",1,xFilial("SF2")+M->ZF5_DOCOC+M->ZF5_SEROC,"F2_I_REDP"))+" - "+SF2->F2_I_RELO+" - "+AllTrim(Posicione("SA2",1,xFilial("SA2")+SF2->F2_I_REDP+SF2->F2_I_RELO,"A2_NOME"))'
 _aGatAux := FwStruTrigger( 'ZF5_DOCOC','F2_I_REDP', _cGatilho2 , .F. )
 _oStrCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

 _oStrITN:AddField( ;
        '' , ;                      // [01] C Titulo do campo                                                 //cTitulo	 Caracteres	Titulo do campo	    X
        "LEGENDA", ;                // [02] C ToolTip do campo                                                //cTooltip Caracteres	Tooltip do campo    X
        "LEGENDA", ;                // [03] C identificador (ID) do Field                                     //cIdField Caracteres	Id do Field	        X
        'C' , ;                     // [04] C Tipo do campo                                                   //cTipo	 Caracteres	Tipo do campo	    X
        50  , ;                     // [05] N Tamanho do campo                                                //nTamanho Numérico	Tamanho do campo    X
        0   , ;                     // [06] N Decimal do campo                                                //nDecimal Numérico	Decimal do campo    0
        NIL , ;                     // [07] B Code-block de validação do campo                                //bValid	 CodeBlock  Bloco de código de validação do campo {|| .T.}
        NIL , ;                     // [08] B Code-block de validação When do campo                           //bWhen    CodeBlock	Bloco de código de validação when do campo
        NIL , ;                     // [09] A Lista de valores permitido do campo                             //aValues	 Array	    Lista de valores permitido do campo	{}
        NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório                 //lObrigat Lógico	    Indica se o campo tem preenchimento obrigatório	.F.
        { || AOMS03Leg(.T.) } , ;   // [11] B Code-block de inicializacao do campo                            //bInit	 CodeBlock	Bloco de código de inicialização do campo
        NIL , ;                     // [12] L Indica se trata de um campo chave                               //lKey	 Lógico	    Indica se trata-se de um campo chave X
        .F. , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update. //lNoUpd	 Lógico	    Indica se o campo não pode receber valor em uma operação de update	.F.
        .T. )                       // [14] L Indica se o campo é virtual                                     //lVirtual Lógico	    Indica se o campo é virtual	.F.
                                                                                                              //cValid	 Caracteres	Valid do usuário em formato texto e sem alteração, usado para se criar o aHeader de compatibilidade	""
 _bValid := {|_oModel| U_AOMS003Q(_oModel)}// Validação do modelo de dados - OK FINAL
 _bCommit:= {|_oModel| U_AOMS003O(_oModel)}

 // Inicializa e configura o modelo de dados
 _oModel  := MPFormModel():New( 'AOMS003M' , /*{|_oModel| U_AOMS03MP(_oModel)}/*Pré-Validação*/, _bValid                      , _bCommit)

 _oModel:SetDescription( 'Ocorrências de Frete' )

 _oModel:AddFields( 'ZF5MASTER' ,, _oStrCAB )

 _bLinePre  := {|_oModel, _nLine, _cAction, _cField, _cValue, _cOldValue| U_AOMS003P(_oModel, _nLine, _cAction, _cField, _cValue, _cOldValue)}
 _bLinePost := {|_oModel, _nLine, _cAction, _cField| U_AOMS003N(_oModel, _nLine, _cAction, _cField)}// Seria o equivalente ao antigo processo de LinhaOk.
 //      AddGrid(<cId >     ,<cOwner >  ,<oModelStruct, _bLinePre,_bLinePost , _bPre > , _bLinePost >, _bLoad >)
 _oModel:AddGrid('ZF5DETAIL',"ZF5MASTER",_oStrITN     ,          ,_bLinePost ,_bLinePre)

 _oModel:GetModel( 'ZF5MASTER' ):SetDescription( 'Dados da Nota Fiscal'	)
 _oModel:GetModel( 'ZF5DETAIL' ):SetDescription( 'Dados das Ocorrencias de Frete'	)

 _oModel:SetRelation( "ZF5DETAIL" , {	{ "ZF5_FILIAL",'xFilial("ZF5")'},;
                                       { "ZF5_DOCOC" ,"ZF5_DOCOC"     },;
                                       { "ZF5_SEROC" ,"ZF5_SEROC"     }}, ZF5->( IndexKey( 1 ) ) )

 _oModel:GetModel( 'ZF5DETAIL' ):SetUniqueLine( { 'ZF5_CODIGO' } )

 _oModel:SetPrimaryKey( { 'ZF5_FILIAL' , 'ZF5_DOCOC' , 'ZF5_SEROC', 'ZF5_CODIGO' } )

Return( _oModel )

/*
===============================================================================================================================
Programa--------: ViewDef
Autor-----------: Josué Danich Prestes
Data da Criacao-: 13/04/2016
Descrição-------: Rotina de definição da View do MVC
Parametros------: Nenhum
Retorno---------: oView - Objeto de exibição do MVC
===============================================================================================================================
*/
Static Function ViewDef()

 Local _oStrCAB:= FWFormStruct( 2 , "ZF5" , {|_cCampo| AOMS003CPO( _cCampo , 1 ) } )
 Local _oStrITN:= FWFormStruct( 2 , "ZF5" , {|_cCampo| AOMS003CPO( _cCampo , 2 ) } )
 Local _oModel	:= FWLoadModel( "AOMS003" )
 Local _oView	:= Nil

 _oStrCAB:AddField( ;                           // Ord. Tipo Desc.
        'F2_I_PENCL'                     , ;    // [01] C   Nome do Campo
        "9L"                             , ;    // [02] C   Ordem
        'Previsão de Entrega do Cliente' , ;    // [03] C   Titulo do campo
        'Previsão de Entrega do Cliente' , ;    // [04] C   Descricao do campo
        {"Previsão de Entrega do Cliente"},;    // [05] A   Array com Help
        'C'                              , ;    // [06] C   Tipo do campo
        '@D'                             , ;    // [07] C   Picture
        NIL                              , ;    // [08] B   Bloco de Picture Var
        ''                               , ;    // [09] C   Consulta F3
        .F.                              , ;    // [10] L   Indica se o campo é alteravel
        NIL                              , ;    // [11] C   Pasta do campo
        NIL                              , ;    // [12] C   Agrupamento do campo
        NIL                              , ;    // [13] A   Lista de valores permitido do campo (Combo)
        NIL                              , ;    // [14] N   Tamanho maximo da maior opção do combo
        NIL                              , ;    // [15] C   Inicializador de Browse
        .T.                              , ;    // [16] L   Indica se o campo é virtual
        NIL                              , ;    // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo

 _oStrCAB:AddField( ;                           // Ord. Tipo Desc.
        'C5_I_AGEND'                    , ;     // [01] C   Nome do Campo
        "9M"                            , ;     // [02] C   Ordem
        'Tipo de Entrega'               , ;     // [03] C   Titulo do campo
        'Tipo de Entrega'               , ;     // [04] C   Descricao do campo
        {"Tipo de Entrega"}             , ;     // [05] A   Array com Help
        'C'                             , ;     // [06] C   Tipo do campo
        '@!'                            , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        .F.                             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo

_oStrCAB:AddField( ;                            // Ord. Tipo Desc.
        'F2_I_OPER'                     , ;     // [01] C   Nome do Campo
        "9N"                            , ;     // [02] C   Ordem
        'Operador Logistico'            , ;     // [03] C   Titulo do campo
        'Operador Logistico'            , ;     // [04] C   Descricao do campo
        {"Operador Logistico"}          , ;     // [05] A   Array com Help
        'C'                             , ;     // [06] C   Tipo do campo
        '@!'                            , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        .F.                             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo

_oStrCAB:AddField( ;                            // Ord. Tipo Desc.
        'F2_I_REDP'                     , ;     // [01] C   Nome do Campo
        "9O"                            , ;     // [02] C   Ordem
        'Redespacho'                    , ;     // [03] C   Titulo do campo
        'Redespacho'                    , ;     // [04] C   Descricao do campo
        {'Redespacho'        }          , ;     // [05] A   Array com Help
        'C'                             , ;     // [06] C   Tipo do campo
        '@!'                            , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        .F.                             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo

 _oStrITN:AddField( ;                           // Ord. Tipo Desc.
        'LEGENDA'                       , ;     // [01] C   Nome do Campo
        "00"                            , ;     // [02] C   Ordem
        ''                              , ;     // [03] C   Titulo do campo
        ''                              , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'C'                             , ;     // [06] C   Tipo do campo
        '@BMP'                          , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        .T.                             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo

 // Inicializa o Objeto da View
 _oView := FWFormView():New()

 _oView:SetModel( _oModel )

 _oView:AddField( "VIEW_CAB" , _oStrCAB , "ZF5MASTER" )
 _oView:AddGrid(  "VIEW_ITN" , _oStrITN , "ZF5DETAIL" )

 _oView:CreateHorizontalBox( 'BOX0101' , 070 )
 _oView:CreateHorizontalBox( 'BOX0102' , 030 )

 _oView:SetOwnerView( "VIEW_CAB" , "BOX0101" )
 _oView:SetOwnerView( "VIEW_ITN" , "BOX0102" )


Return( _oView )


/*
===============================================================================================================================
Programa--------: AOMS003CPO
Autor-----------: Josué Danich Prestes
Data da Criacao-: 13/04/2016
Descrição-------: Configuração da inicialização de campos na tela
Parametros------: _cCampo: list de campos    ; _nOpc : inverte a lista
Retorno---------: oView - Objeto de exibição do MVC
===============================================================================================================================
*/
Static Function AOMS003CPO( _cCampo , _nOpc )

 Local _ccampos := ""
 Local _lRet := .F.

 _ccampos := 'ZF5_DOCOC;'
 _ccampos += 'ZF5_SEROC;'
 _ccampos += 'ZF5_REPRES;'
 _ccampos += 'ZF5_DATAE;'
 _ccampos += "ZF5_ASSNOM;"
 _ccampos += 'ZF5_VLRFRE;'
 _ccampos += 'ZF5_AGENDA;'
 _ccampos += 'ZF5_VOLUM;'
 _ccampos += 'ZF5_PEDIDO;'
 _ccampos += 'ZF5_TIPOV;'
 _ccampos += 'ZF5_COORD;'
 _ccampos += 'ZF5_NCOOR;'
 _ccampos += 'ZF5_CLIENT;'
 _ccampos += 'ZF5_NREPRE;'
 _ccampos += 'ZF5_PESON;'
 _ccampos += 'ZF5_LOJA;'
 _ccampos += 'ZF5_NCLIEN;'
 _ccampos += 'ZF5_UF;'
 _ccampos += 'ZF5_CIDADE;'
 _ccampos += 'ZF5_SEQCAR;'
 _ccampos += 'ZF5_CARGA;'
 _ccampos += 'ZF5_MOTORI;'
 _ccampos += 'ZF5_DMOTOR;'
 _ccampos += 'ZF5_VEICUL;'
 _ccampos += 'ZF5_DVEICU;'
 _ccampos += 'ZF5_DTCAR;'
 _ccampos += 'ZF5_PESO;'
 _ccampos += 'ZF5_DATAL;'
 _ccampos += 'ZF5_HORAL;'
 _ccampos += 'ZF5_DATAC;'
 _ccampos += 'ZF5_HORAC;'
 _ccampos += 'ZF5_RPCOM;'
 _ccampos += 'ZF5_RPLOGI;'
 _ccampos += 'ZF5_NRPCO;'
 _ccampos += 'ZF5_NRPLO;'
 _ccampos += 'ZF5_OBSFR;'
 _ccampos += 'ZF5_POSTOF;'
 _ccampos += 'ZF5_TELEFO;'
 _ccampos += 'ZF5_DAE;'
 _ccampos += 'ZF5_VALORI;'
 _ccampos += 'ZF5_SENHAM;'
 _ccampos += 'ZF5_OBSPF;'
 _ccampos += 'ZF5_PLACA;'
 _ccampos += 'ZF5_DATAS;'
 _ccampos += 'ZF5_HORAS;'
 _ccampos += "ZF5_GERENT;"
 _ccampos += "ZF5_NGEREN;"
 _ccampos += "ZF5_MERENT;"
 _ccampos += "ZF5_SITENT;"
 _ccampos += "ZF5_OPRLOG;"
 _cCampos += "ZF5_LOJOPE;"
 _cCampos += "ZF5_CGCOPR;"
 _cCampos += "ZF5_NOMOPE;"
 _cCampos += "ZF5_ESTOPE;"
 _cCampos += "ZF5_MUNOPE;"
 _cCampos += "ZF5_DDDOPE;"
 _cCampos += "ZF5_TELOPE;"

 _lRet := AllTrim(_cCampo) $ _ccampos

 If _nOpc == 2
     _lRet := !_lRet
 EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa--------: AOMS003Z
Autor-----------: Josué Danich Prestes
Data da Criacao-: 13/04/2016
Descrição-------: Gatilha campos automáticos do cabeçalho
Parametros------: _ccampo - nome do campo a ser preenchido
                  _nopc   - 1 usa M->ZF5_DOCOC
                            2 usa ZF5->ZF5_DOCOC
Retorno---------: _cret - valor do campo
===============================================================================================================================
*/
User Function AOMS003Z(_ccampo,_nopc)

 Local _cret := ""
 Local _cret3 := ""
 Local _cret4 := ""
 Local _cdococ := ""
 Local _aOrd := SaveOrd({"SF2","ZFC"})
 Local _cCarga, _cMotorista //, _cOPer
 Local _oModel
 Local _oModelMaster
 Local _oModelGrid
 Local _cTipoOcorr, _cFornece

 Default _nopc := 1

 If ! isincallstack("U_AOMS03M") .And. !isincallstack("U_AOMS072I")
    _oModel       := FWModelActive()
    _oModelMaster := _oModel:GetModel("ZF5MASTER")//Sempre teste se a variavel ValType(_oModelMaster) = "O" ao usar abaixo para previnir
    _oModelGrid   := _oModel:GetModel("ZF5DETAIL")//Sempre teste se a variavel ValType(_oModelGrid)   = "O" ao usar abaixo para previnir
    M->ZF5_SEROC  := AllTrim(_oModelMaster:GetValue('ZF5_SEROC'))
 EndIf

 If _NOPC == 1 .And. !inclui//VISUAL
    _cSerie := ZF5->ZF5_SEROC
    _cdococ := ZF5->ZF5_DOCOC+_cSerie
    M->ZF5_DOCOC:=ZF5->ZF5_DOCOC
 ElseIf _NOPC == 2 .Or. inclui//INCLUSAO E CHAMDO DO AOMS072.PRW TB
    _cSerie := AllTrim(M->ZF5_SEROC)
    _cdococ := M->ZF5_DOCOC+_cSerie
 ElseIf _NOPC == 3//ALTERACAO
    ZF5->(DBGoTo( (cAliasAux)->REC_ZF5 ))
    _cSerie := ZF5->ZF5_SEROC
    _cdococ := ZF5->ZF5_DOCOC+_cSerie
    M->ZF5_DOCOC:=ZF5->ZF5_DOCOC
 EndIf

 SF2->(DBSetOrder(1))
 SF2->(DBSeek(xFilial("SF2")+AllTrim(_cdococ)))

 If _ccampo == "ZF5_DATAE"
    _cret := Posicione("SC5",,xFilial("SC5")+M->ZF5_DOCOC,"C5_I_DTENT","IT_NOTA")
 ElseIf _ccampo == "ZF5_ASSNOM"
    _cret := Posicione("SC5",,xFilial("SC5")+M->ZF5_DOCOC,"C5_ASSNOM","IT_NOTA")
 EndIf

 If _ccampo == "ZF5_CARGA"
    If ! Empty(SF2->F2_CARGA)
       _cret := SF2->F2_CARGA
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_SEQCAR"
    If ! Empty(SF2->F2_SEQCAR)
       _cret := SF2->F2_SEQCAR
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_MOTORI"
    If ! Empty(SF2->F2_CARGA)
        _cret := Posicione("DAK",1,xFilial("ZF5")+SF2->F2_CARGA,"DAK_MOTORI")
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_DMOTOR"
    If !Empty(SF2->F2_CARGA)
       _cret := SubStr(AllTrim(Posicione("DA4",1,xFilial("DA4")+Posicione("DAK",1,xFilial("ZF5")+AllTrim(SF2->F2_CARGA),"DAK_MOTORI") ,"DA4_NOME")),1,30)
          _cret3 := StrTran(StrTran(AllTrim(Posicione("DA4",1,xFilial("DA4")+Posicione("DAK",1,xFilial("ZF5")+AllTrim(SF2->F2_CARGA),"DAK_MOTORI") ,"DA4_TEL")),"-","")," ","")
          _cret3 := StrTran(_cret3,".","")
       _cret4:=""
       If LEFT(_cret3,1) = "0"
          _cret3 := SubStr(_cret3,2)//Tiro o zero
          _cret4 := " - (" + LEFT(_cret3,2) + ") "
          _cret  += _cret4 + SubStr(_cret3,3)
       ElseIf Len(_cret3) > 9  .And. Len(_cret3) < 12
          _cret4 := " - (" + LEFT(_cret3,2) + ") "
          _cret  += _cret4 + SubStr(_cret3,3)
       Else
          _cret  += " - " + _cret3
       EndIf

    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_VEICUL"
    If ! Empty(SF2->F2_CARGA)
       _cret := Posicione("DAK",1,xFilial("ZF5")+AllTrim(SF2->F2_CARGA),"DAK_CAMINH")
    Else
       _cret :=  ""
    EndIf
 EndIf

 If _ccampo == "ZF5_DVEICU"
    If ! Empty(SF2->F2_CARGA)
       _cret3 := Posicione("DAK",1,xFilial("ZF5")+SF2->F2_CARGA,"DAK_CAMINH")
       _cret := Posicione("DA3",1,xFilial("DA3")+AllTrim(_cret3),"DA3_DESC")
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_PLACA"
    If ! Empty(SF2->F2_CARGA)
       _cret3 := Posicione("DAK",1,xFilial("ZF5")+AllTrim(SF2->F2_CARGA),"DAK_CAMINH")
       _cret := Posicione("DA3",1,xFilial("DA3")+AllTrim(_cret3),"DA3_PLACA")
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_DTCAR"
    If ! Empty(SF2->F2_CARGA)
       _cret := Posicione("DAK",1,xFilial("ZF5")+AllTrim(SF2->F2_CARGA),"DAK_DATA")
    Else
       _cret := CTod("")
    EndIf
 EndIf

 If _ccampo == "ZF5_PESO"
    If ! Empty(SF2->F2_CARGA)
       _cret  := Posicione("DAK",1,xFilial("ZF5")+SF2->F2_CARGA,"DAK_PESO")
    Else
       _cret := 0
    EndIf
 EndIf

 If _ccampo == "ZF5_REPRES"
    If ! Empty(SF2->F2_VEND1)
       _cret := SF2->F2_VEND1
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_NREPRE"
    If !Empty(SF2->F2_VEND1)
        _cret := SubStr(AllTrim(Posicione("SA3",1,xFilial("SA3")+SF2->F2_VEND1,"A3_NOME")),1,30)
        _cret3 := AllTrim(Posicione("SA3",1,xFilial("SA3")+SF2->F2_VEND1,"A3_TEL"))
        _cret4 := AllTrim(Posicione("SA3",1,xFilial("SA3")+SF2->F2_VEND1,"A3_DDDTEL"))

      _cret += " - (" + _cret4 + ") " + _cret3
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_COORD"
    If ! Empty(SF2->F2_VEND2)
       _cret := SF2->F2_VEND2
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_NCOOR"
    If ! Empty(SF2->F2_VEND2)
       _cret  := SubStr(AllTrim(Posicione("SA3",1,xFilial("SA3")+SF2->F2_VEND2,"A3_NOME")),1,30)
       _cret3 := AllTrim(Posicione("SA3",1,xFilial("SA3")+SF2->F2_VEND2,"A3_TEL"))
       _cret4 := AllTrim(Posicione("SA3",1,xFilial("SA3")+SF2->F2_VEND2,"A3_DDDTEL"))
       _cret  += " - (" + _cret4 + ") " + _cret3
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_CLIENT"
    If ! Empty(SF2->F2_CLIENTE)
       _cret := SF2->F2_CLIENTE
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_LOJA"
    If ! Empty(SF2->F2_LOJA)
       _cret := SF2->F2_LOJA
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_NCLIEN"
    If !Empty(SF2->F2_CLIENTE)
       _cret  := SubStr(AllTrim(Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_NREDUZ")),1,30)
       _cret3 := AllTrim(Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_TEL"))
       _cret4 := AllTrim(Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_DDD"))
       _cret += " - (" + _cret4 + ") " + _cret3
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_UF"
    If ! Empty(SF2->F2_EST)
       _cret := SF2->F2_EST
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_SEROC"
    If ! Empty(SF2->F2_SERIE)
       _cret := SF2->F2_SERIE
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_CIDADE"
    If ! Empty(SF2->F2_CLIENTE)
        _cret := Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_MUN")
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_PESON"
    If ! Empty(SF2->F2_PBRUTO)
       _cret := SF2->F2_PBRUTO
    Else
       _cret := 0
    EndIf
 EndIf

 If _ccampo == "ZF5_VOLUM"
    If ! Empty(SF2->F2_VOLUME1)
       _cret := Transform(SF2->F2_VOLUME1,"@E 999,999")
       _cret += "  " + AllTrim(SF2->F2_ESPECI1)
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_TIPOV"
    If ! Empty(SF2->F2_CARGA)
       _cret3 := Posicione("DAK",1,xFilial("ZF5")+SF2->F2_CARGA,"DAK_CAMINH")
       _cret := Posicione("DA3",1,xFilial("DA3")+AllTrim(_cret3),"DA3_I_TPVC")
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_VLRFRE"
    If ! Empty(SF2->F2_I_FRET)
       _cret := SF2->F2_I_FRET
    Else
       _cret := 0
    EndIf
 EndIf

 If _ccampo == "ZF5_PEDIDO"
    If ! Empty(SF2->F2_I_PEDID)
       _cret := 	SF2->F2_I_PEDID
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_GERENT"
    If ! Empty(SF2->F2_VEND3)
       _cret := SF2->F2_VEND3
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_NGEREN"
    If ! Empty(SF2->F2_VEND3)
        _cret  := SubStr(AllTrim(Posicione("SA3",1,xFilial("SA3")+SF2->F2_VEND3,"A3_NOME")),1,30)
        _cret3 := AllTrim(Posicione("SA3",1,xFilial("SA3")+SF2->F2_VEND3,"A3_TEL"))
        _cret4 := AllTrim(Posicione("SA3",1,xFilial("SA3")+SF2->F2_VEND3,"A3_DDDTEL"))

      _cret += " - (" + _cret4 + ") " + _cret3
    Else
       _cret := ""
    EndIf
 EndIf

 If _ccampo == "ZF5_RPCOM" .And. ! isincallstack("U_AOMS03M")
    _cret := Embaralha(Posicione("SC5",,xFilial("SC5")+M->ZF5_DOCOC,"C5_USERLGI","IT_NOTA"),1)
    _cret := SubStr(_cret,3,6)
    _oModelMaster:SetValue('ZF5_NRPCO',UsrRetName(_cret))
 EndIf

 If _ccampo == 'ZF5_TIPOO'
    _cTipoOcorr := M->ZF5_TIPOO
    _cret := _cTipoOcorr

    _cCarga := Posicione("SF2",1,xFilial("SF2")+AllTrim(M->ZF5_DOCOC+M->ZF5_SEROC),"F2_CARGA")
    If Empty(_cCarga) //SE TIVER CARGA PEGA DA CARGA SENÃO DO SF2
       _cFornece   := SF2->F2_I_CTRA
       _cLoja      := SF2->F2_I_LTRA
       _cNome      :=  Posicione("SA2",1,xFilial("SA2")+_cFornece+_cLoja, "A2_NREDUZ")
    Else
       _cMotorista := Posicione("DAK",1,xFilial("DAK")+_cCarga,"DAK_MOTORI")
       _cFornece   := Posicione("DA4",1,xFilial("DA4")+_cMotorista, "DA4_FORNEC")
       _cLoja      := DA4->DA4_LOJA
       _cNome      := Posicione("SA2",1,xFilial("SA2")+_cFornece+_cLoja, "A2_NREDUZ")
    EndIf
    If ValType(_oModelGrid) = "O"
       _oModelGrid:LoadValue("ZF5_TRANSP",_cFornece)
       _oModelGrid:LoadValue("ZF5_LJTRAN",_cLoja)
       _oModelGrid:LoadValue("ZF5_NTRANS",_cNome)
    EndIf
 EndIf


 If _ccampo == 'ZF5_TIPOC'
    _cTipoOcorr := M->ZF5_TIPOO
    _cret := ""

    If ! Empty(_cTipoOcorr)
       ZFC->(DBSetOrder(1))
       ZFC->(DBSeek(xFilial("ZFC")+_cTipoOcorr))
       _cret := ZFC->ZFC_CUSTO
       RestOrd(_aOrd)
    EndIf
 EndIf

 If _ccampo == 'ZF5_DEVOL'
    _cTipoOcorr := M->ZF5_TIPOO
    _cret := ""

    If ! Empty(_cTipoOcorr)
       ZFC->(DBSetOrder(1))
       ZFC->(DBSeek(xFilial("ZFC")+_cTipoOcorr))
       _cret := ZFC->ZFC_DEVOL
       RestOrd(_aOrd)
    EndIf
 EndIf

 If _ccampo == 'ZF5_SERVIC'
    _cTipoOcorr := M->ZF5_TIPOO
    _cret := ""

    If ! Empty(_cTipoOcorr)
       ZFC->(DBSetOrder(1))
       ZFC->(DBSeek(xFilial("ZFC")+_cTipoOcorr))
       _cret := ZFC->ZFC_SERVI
       RestOrd(_aOrd)
    EndIf
 EndIf

If _ccampo == 'ZF5_RPLOGI' .And. ! FWIsInCallStack("U_AOMS03M")
    _cret := AllTrim(SuperGetMV('IT_RESPLOG',.T.,''))
    _oModelMaster:SetValue('ZF5_NRPLO',UsrRetName(_cret))
 EndIf

Return _cret

/*
===============================================================================================================================
Programa--------: AOMS003H
Autor-----------: Josué Danich Prestes
Data da Criacao-: 13/04/2016
Descrição-------: Legenda para o fwbrowse principal
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS003H()

 Local aLegenda := {}
 //Monta as cores
 aAdd(aLegenda,{"BR_VERDE",   "Pendente"  })
 aAdd(aLegenda,{"BR_VERMELHO","Encerrada"})
 aAdd(aLegenda,{"BR_CINZA",   "Não Procede"})
 aAdd(aLegenda,{"BR_AMARELO", "Em tratamento"})
 BrwLegenda("Ocorrências de Frete", "Frete", aLegenda)

Return

/*
===============================================================================================================================
Programa--------: AOMS003K
Autor-----------: Josué Danich Prestes
Data da Criacao-: 13/04/2016
Descrição-------: Inicializa código da ocorrencia
Parametros------: _lUsaMVC - Indica se a rotina que chamou esta função utiliza MVC (True), ou não utiliza MVC (False)
                  _cNomeFonte - Nome do fonte que chamou esta função.
Retorno   ------: _cret - novo código de ocorrência
===============================================================================================================================
*/
User Function AOMS003K(_lUsaMVC, _cNomeFonte)

 Local _cret := "000001"
 Local _oModel
 Local _oModelGrid

 Default _lUsaMVC := .T., _cNomeFonte := "AOMS003"

 Begin Sequence
   If _lUsaMVC .And. _cNomeFonte == "AOMS003"
      _oModel      := FwModelActivete()
      _oModelGrid  := _oModel:GetModel("ZF5DETAIL")

      _nUltReg:=_oModelGrid:Length()
      If _nUltReg > 0
         _oModelGrid:GoLine(_nUltReg)
         _nProx:=Val(_oModelGrid:GetValue('ZF5_CODIGO'))+1
      Else
         _nProx:=_oModelGrid:GetLine()+1
      EndIf

      _cret := StrZero(_nProx,6)

   ElseIf !  _lUsaMVC .And. _cNomeFonte == "AOMS072"
      _cret := StrZero(Len(aCols),6)
   EndIf

 End Sequence

Return _cret

/*
===============================================================================================================================
Programa--------: AOMS003V
Autor-----------: Josué Danich Prestes
Data da Criacao-: 13/04/2016
Descrição-------: Valida numero de nota duplicado
Parametros------: Nenhum
Retorno   ------: Lógico validando ou não o numero de nota
===============================================================================================================================
*/
User Function AOMS003V()

 Local _lRet := .T. As Logical
 Local _cQuery := "" As Character
 Local cAlias:=GetNextAlias() As Character

 _cQuery := " SELECT ZF5_TRANSP,ZF5_LJTRAN,ZF5_NTRANS"
 _cQuery += " FROM " + RetSqlName("ZF5") + " ZF5"
 _cQuery += " WHERE ZF5.ZF5_FILIAL = '" + xFilial("ZF5") + "'"
 _cQuery += " AND ZF5.ZF5_DOCOC = '" + M->ZF5_DOCOC + "'"
 _cQuery += " AND ZF5.D_E_L_E_T_ = ' ' "

 MPSysOpenQuery( _cQuery , cAlias)

 _ctransp := ""

 While .not. (cAlias)->( Eof() )

    If !(cAlias)->ZF5_TRANSP + "/" + (cAlias)->ZF5_LJTRAN $ _ctransp
        _ctransp += (cAlias)->ZF5_TRANSP + "/" + (cAlias)->ZF5_LJTRAN + " - " + AllTrim((cAlias)->ZF5_NTRANS) + CHR(10) +CHR(13)
    EndIf

     (cAlias)->(DBSkip())

 EndDo

 (cAlias)->( DBCloseArea() )

 If Len(_ctransp) > 0

    (U_ITMsg("Já existe ocorrência para nota!","Atenção",;
             "Ocorrência, já cadastrada para o(s) transportador(es) abaixo, " + ;
             ", para adicionar eventos nesse(s) transportador(s) ou outro use a opção alterar:" + chr(10) + chr(13) + _ctransp ,,,,.T.))
    _lRet := .F.

 EndIf

 If _lRet
 
    _cSeek := M->ZF5_DOCOC+AllTrim(M->ZF5_SEROC)
    SF2->(DBSetOrder(1))
    If SF2->(DBSeek(xFilial("SF2")+_cSeek)) .And. SF2->F2_CLIENTE = "000001"
       If (Posicione("SC5",,xFilial("SC5")+M->ZF5_DOCOC,"C5_I_TRCNF","IT_NOTA") = "S") .And. SC5->C5_I_OPER = "20"
          _cSeekPV:=SC5->C5_I_FILFT+SC5->C5_I_PDFT
          cNotaFat:=Posicione("SC5",1,_cSeekPV,"C5_NOTA")
          cNotaFat:=SC5->C5_FILIAL+" "+cNotaFat+" - "+SC5->C5_SERIE
          U_ITMsg("Inclusão de Ocorrência de Nfe de Transferência, somente permitido para Nota de Venda vinculada a transferência","Atenção","NFe de Venda vinculada: "+cNotaFat,,,,.T.)
          _lRet := .F.
       EndIf
    EndIf

 EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: AOMS003W
Autor-----------: Julio de Paula Paz
Data da Criacao-: 02/06/2016
Descrição-------: Define tratamentos para campos, de acordo com o campo passado como parâmetro, como fazer inicialização
                  padrão, validar campos,
Parametros------: _cCampo = campo que chamou a rotina.
Retorno   ------: True ou False,valores de inicalização de campos.
===============================================================================================================================
*/
User Function AOMS003W(_cCampo,_lMVC,_cFonte)

 Local _lxRet := .T.
 Local _oModel           := FwModelActivete()
 Local _oModelGrid       := _oModel:GetModel("ZF5DETAIL")
 Local _oModelMaster     := _oModel:GetModel("ZF5MASTER")
 Local _lCustoPreenchido := .T.
 Local _cCodFor, _cLojaFor, _cNomeFor, _nCustoTer
 Local _aOrd := SaveOrd({"SA2","SF2","SC5"})
 Local _cForPadrao := SuperGetMV('IT_FORTERC',.T.,'F046200020') // Como default deste parâmetro está o Fornecedor terceiro: Codigo: F04620 - Loja: 0020 - Nome: CASTROLANDA COOP AGROINDUSTRIA
 Local _cNumNf, _cSerieNf
 Local _nVlCobradoTon, _nPeso, _cCarga, _nCusto

 Default _lMVC := .T., _cFonte := "AOMS003"

 Begin Sequence

   If ! _lMVC
      If _cFonte == "AOMS072"
         _lxRet := U_AOMS072E(_cCampo)
      EndIf
      Break
   EndIf

   If _cCampo == 'ZF5_OLRCOD'
      ZFC->(DBSetOrder(1))
      ZFC->(DBSeek(xFilial("ZFC")+_oModelGrid:GetValue("ZF5_TIPOO")))
      If !Empty(M->ZF5_OLRCOD)
         If ZFC->ZFC_OLREDI  <> "S"
            U_ITMsg('Tipo de ocorrecia não é de redirecionamento. (ZFC_OLREDI<>"S").','Atenção',;
                    'O Codigo do operador logistico do redirecionamento não pode ser informado.',,,,.T.)
            _lxRet := .F.
            _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_OLRLOJ', Space(Len(ZF5->ZF5_OLRLOJ)))
            _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_OLRNOM', Space(Len(ZF5->ZF5_OLRNOM)))

         ElseIf SA2->(DBSeek(xFilial("SA2")+M->ZF5_OLRCOD)) 
            _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_OLRLOJ', SA2->A2_LOJA)
            _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_OLRNOM', LEFT(SA2->A2_NOME,Len(ZF5->ZF5_OLRNOM) ))
         Else
            U_ITMsg("Código de Transportadora não cadastrado  no cadastro de fornecedores.","Atenção",,,,,.T.)
            _lxRet := .F.
         EndIf
      Else
         If ZFC->ZFC_OLREDI == "S"
            U_ITMsg('Tipo de ocorrecia é de redirecionamento. (ZFC_OLREDI="S").','Atenção',;
                    "Informe o Codigo+loja do operador logistico do redirecionamento.",,,,.T.)
            _lxRet := .F.
         Else
            _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_OLRLOJ', Space(Len(ZF5->ZF5_OLRLOJ)))
            _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_OLRNOM', Space(Len(ZF5->ZF5_OLRNOM)))
         EndIf
      EndIf
      Break
   ElseIf _cCampo == 'ZF5_OLRLOJ'
      If !Empty(_oModel:GetValue( 'ZF5DETAIL', 'ZF5_OLRCOD')) .Or. !Empty(M->ZF5_OLRLOJ)
         If SA2->(DBSeek(xFilial("SA2")+_oModel:GetValue( 'ZF5DETAIL', 'ZF5_OLRCOD')+M->ZF5_OLRLOJ))
            _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_OLRNOM', LEFT(SA2->A2_NOME,Len(ZF5->ZF5_OLRNOM) ))
         Else
            U_ITMsg("Código+loja de Transportadora não cadastrado no cadastro de fornecedores.","Atenção",,,,,.T.)
            _lxRet := .F.
         EndIf
      Else//Se os 2 em branco, limpa
         _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_OLRNOM', Space(Len(ZF5->ZF5_OLRNOM)))
      EndIf
      Break
   EndIf

   _nCustoTer := _oModel:GetValue( 'ZF5DETAIL', 'ZF5_CUSTER' )
   If Empty(_nCustoTer)
      _lCustoPreenchido := .F.
   EndIf

   _cCodFor  := _oModel:GetValue( 'ZF5DETAIL', 'ZF5_FORTER' )
   _cLojaFor := _oModel:GetValue( 'ZF5DETAIL', 'ZF5_LOJTER' )
   _cNomeFor := _oModel:GetValue( 'ZF5DETAIL', 'ZF5_NOMTER' )

   SA2->(DBSetOrder(1))
   SF2->(DBSetOrder(1))
   SC5->(DBSetOrder(1))

   If _cCampo == 'ZF5_CUSTER'
      If Empty(_nCustoTer)
         _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_FORTER', Space(6))
         _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_LOJTER', Space(4))
         _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_NOMTER', Space(Len(ZF5->ZF5_NOMTER)))
      ElseIf Empty(_cCodFor)
         SA2->(DBSeek(xFilial("SA2")+_cForPadrao))
         _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_FORTER', SA2->A2_COD)
         _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_LOJTER', SA2->A2_LOJA)
         _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_NOMTER', LEFT(SA2->A2_NOME,Len(ZF5->ZF5_NOMTER) ))
      EndIf

   ElseIf _cCampo == 'ZF5_FORTER'
      If ! _lCustoPreenchido .And. ! Empty(_cCodFor)
         U_ITMsg("O campo custo de terceiro precisa ser preenchido.","Atenção",,1)
         _lxRet := .F.
         Break
      EndIf

      If _lCustoPreenchido
         If ! SA2->(DBSeek(xFilial("SA2")+_cCodFor))
            U_ITMsg("Código de Terceiro não cadastrado no cadastro de fornecedores.","Atenção",,1)
            _lxRet := .F.
            Break
         Else
            _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_LOJTER', SA2->A2_LOJA)
            _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_NOMTER', LEFT(SA2->A2_NOME,Len(ZF5->ZF5_NOMTER)))
         EndIf
      EndIf

   ElseIf _cCampo == 'ZF5_LOJTER'
      If ! _lCustoPreenchido .And. ! Empty(_cLojaFor)
         U_ITMsg("O campo custo de terceiro precisa ser preenchido.","Atenção",,1)
         _lxRet := .F.
         Break
      EndIf

      If _lCustoPreenchido
         If ! SA2->(DBSeek(xFilial("SA2")+_cCodFor+_cLojaFor))
            U_ITMsg("Código+Loja de Terceiro não cadastrado no cadastro de fornecedores.","Atenção",,1)
            _lxRet := .F.
            Break
         Else
            _oModel:LoadValue( 'ZF5DETAIL', 'ZF5_NOMTER', LEFT(SA2->A2_NOME,Len(ZF5->ZF5_NOMTER)))
         EndIf
      EndIf

   ElseIf _cCampo == 'ZF5_NOMTER'
      If ! _lCustoPreenchido .And. ! Empty(_cNomeFor)
         U_ITMsg("O campo custo de terceiro precisa ser preenchido.","Atenção",,1)
         _lxRet := .F.
         Break
      EndIf

   ElseIf _cCampo == 'ZF5_AGENDA'
      _cNumNf   := _oModelMaster:GetValue('ZF5_DOCOC' )
      _cSerieNf := AllTrim(_oModelMaster:GetValue('ZF5_SEROC' ))
      SF2->(DBSeek(xFilial("SF2")+_cNumNf+_cSerieNf))
      SC5->(DBSeek(SF2->(F2_FILIAL+F2_I_PEDIDO)))
      _oModelMaster:LoadValue('ZF5_AGENDA', AllTrim(SC5->C5_MENNOTA))
      _lxRet := AllTrim(SC5->C5_MENNOTA)

   ElseIf _cCampo == 'ZF5_VALTON'
      _nVlCobradoTon := 0
      _cCarga := Posicione("SF2",1,xFilial("SF2")+AllTrim(ZF5->ZF5_DOCOC+ZF5->ZF5_SEROC),"F2_CARGA")
      _nPeso  := Posicione("DAK",1,xFilial("ZF5")+AllTrim(_cCarga),"DAK_PESO")
      _nCusto := _oModelGrid:GetValue('ZF5_CUSTO' )

      _nVlCobradoTon  += (_nCusto / (_nPeso / 1000))
      _lxRet := _nVlCobradoTon
   ElseIf _cCampo == 'ZF5_VALEMB'

      _lxRet := _oModelGrid:GetValue('ZF5_CUSTO' ) - M->ZF5_VALEMB

   ElseIf _cCampo == 'ZF5_DVITEM'

      _lxret := .T.
      _lnotadev := (_oModelGrid:GetValue('ZF5_DEVOL' ) == "S" )
      _ctipoc := _oModelGrid:GetValue('ZF5_TIPOC' )

      //Se For vazio valida
      If Empty(M->ZF5_DVITEM)
         Break
      EndIf

      //Soma valores de itens selecionados para devolução
      If _lnotadev .And. !Empty(_ctipoc)

         _cforn := AllTrim(_oModelMaster:GetValue('ZF5_CLIENT'))
         _clojaf := AllTrim(_oModelMaster:GetValue('ZF5_LOJA'))

      Else

         U_ITMsg("Selecione tipo de custo e marque a ocorrência como devolução para indicar nota de devolução","Atenção",,1)
         _lxret := .F.
         Break

      EndIf

      //Localiza nota de devolução
      SF1->(DBSetOrder(1))
      If SF1->(DBSeek(xFilial("SF1")+_oModelGrid:GetValue('ZF5_DOCDEV' )+_oModelGrid:GetValue('ZF5_SERDEV')+_cforn+_clojaf))


         SD1->(DBSetOrder(1))
         SD1->(DBSeek(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA))

         _lxret := .T.
         _ntotal := 0

         While SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA == SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA

            If SD1->D1_ITEM $ M->ZF5_DVITEM

               _ntotal += SD1->D1_TOTAL

            EndIf

            SD1->(DBSkip())

         EndDo

         If SuperGetMV("IT_OCVALDE",.T.,.F.)

            //Preenche campos de valores de acordo com a devolução
            _oModelGrid:SetValue('ZF5_CUSTO',_ntotal)
            _oModelGrid:SetValue('ZF5_VLRTOT',_ntotal - _oModelGrid:GetValue('ZF5_VALEMB' ))
            _oModelGrid:SetValue('ZF5_CUSTOI',0)
            _oModelGrid:SetValue('ZF5_CUSTOR',0)
            _oModelGrid:SetValue('ZF5_CUSTOC',0)
            _oModelGrid:SetValue('ZF5_CUSTOT',0)
            _oModelGrid:SetValue('ZF5_CUSTER',0)

            If _ctipoc == "I"
               _oModelGrid:SetValue('ZF5_CUSTOI',_ntotal - _oModelGrid:GetValue('ZF5_VALEMB' ))
            ElseIf _ctipoc == "R"
               _oModelGrid:SetValue('ZF5_CUSTOR',_ntotal - _oModelGrid:GetValue('ZF5_VALEMB' ))
            ElseIf _ctipoc == "C"
               _oModelGrid:SetValue('ZF5_CUSTOC',_ntotal - _oModelGrid:GetValue('ZF5_VALEMB' ))
            ElseIf _ctipoc == "T"
               _oModelGrid:SetValue('ZF5_CUSTOT',_ntotal - _oModelGrid:GetValue('ZF5_VALEMB' ))
            ElseIf _ctipoc == "3"
               _oModelGrid:SetValue('ZF5_CUSTER',_ntotal - _oModelGrid:GetValue('ZF5_VALEMB' ))
            EndIf

         EndIf

         Break

      Else

         U_ITMsg("Nota de devolução não foi localizada","Atenção",,1)
         _lxret := .F.
         Break

      EndIf


   EndIf

 End Sequence

 RestOrd(_aOrd)

Return _lxRet

/*
===============================================================================================================================
Programa--------: AOMS003Q
Autor-----------: Julio de Paula Paz
Data da Criacao-: 18/07/2016
Descrição-------: Realiza as validações do modelo de dados. OK FINAL
Parametros------: _oModel = Modelo de dados
Retorno   ------: True ou False.
===============================================================================================================================
*/
User Function AOMS003Q(_oModel As Object) As Logical
 
 Local _lRet := .T. As Logical
 Local _aOrd := SaveOrd({"ZFC","ZF5"}) As Array
 Local _aArea := GetArea("ZF5") As Array
 Local _oModelGrid   := _oModel:GetModel("ZF5DETAIL") As Object
 Local _oModelMaster := _oModel:GetModel("ZF5MASTER") As Object
 Local _cTipoOcorr := "" As Character
 Local _cTipoCusto := "" As Character
 Local _nI := 0 As Numeric
 Local _nCustoIt := 0 As Numeric
 Local _nCustoCli := 0 As Numeric
 Local _nCustoRepr := 0 As Numeric
 Local _nCustoTransp := 0 As Numeric
 Local _nCustoTerc := 0 As Numeric
 Local _cGerDevol := "" As Character
 Local _cServOcorr := "" As Character
 Local _cNfDev := "" As Character
 Local _cSerDev := "" As Character
 Local _nOperation := _oModel:GetOperation() As Numeric
 Local _lValidaLinha := .F. As Logical
 Local _cStatusOcorr := "" As Character
 Local _cFilial := "" As Character
 Local _cDococ := "" As Character
 Local _cserie := "" As Character
 Local _nK := 0 As Numeric
 Local _nJ := 0 As Numeric
 Local _cNaturOF := ""  As Character
 Local _cPeriodo := ""  As Character
 Local _cEnvCob := "" As Character
 Local _cMotivo  := ""  As Character
 Local _nSlvaLin := _oModelGrid:GetLine()//Salva a linha atual posicionada
 Local _lBloq := .F. As Logical
 Local _cUsersHab := SuperGetMV("IT_USPROTI",.F.,"") As Character
 Local _aAreaM0:= SM0->(FwGetArea()) As Array
 Local _cCodUsu := "" As Character

 Private _cFilOld   := cfilant As Character
 Private _cFilSalva := cfilant As Character

 _lEmail:= .F.//VARIAVEL Static
 _aDadosEmailCom:={}//VARIAVEL Static

 Begin Transaction

 Begin Sequence

   _lEnviou := .F.

   // Ajusta código da Ocorrência de Frete para evitar erro de chave duplicada.
   If _lRet .And. _nOperation == MODEL_OPERATION_INSERT .Or. _nOperation == MODEL_OPERATION_UPDATE

      U_AOMS03MP(_oModel)//Tirei da pre-validacao pq no OK final nem sempre a array _aItOcorre tava preenchida, com isso bagunçava a numeração

      ZF5->(DBSetOrder(4)) // ZF5_FILIAL+ZF5_DOCOC+ZF5_SEROC+ZF5_CODIGO

      If Empty(_aItOcorre)
         _nCodigo := 1
      Else
         _nCodigo := Val(_aItOcorre[1,3])

         For _nI := 1 To Len(_aItOcorre)
             If _nCodigo < Val(_aItOcorre[_nI,3])
                _nCodigo := Val(_aItOcorre[_nI,3])
             EndIf
         Next  _nI
      EndIf

      _nTotOc := Len(_aItOcorre)

      For _nI := 1 To _oModelGrid:Length()
          _oModelGrid:GoLine(_nI)
          If _nI <= _nTotOc
             _oModelGrid:LoadValue('ZF5_CODIGO', _aItOcorre[_nI,3] )
          Else
             While .T.
                _nCodigo += 1

                _cNrNota    := _oModelMaster:GetValue("ZF5_DOCOC")
                   _cSerieNota := _oModelMaster:GetValue("ZF5_SEROC")

                // índice 4 = ZF5_FILIAL+ZF5_DOCOC+ZF5_SEROC+ZF5_CODIGO
                If ZF5->(MsSeek(xFilial("ZF5") + U_ITKEY( _cNrNota,"ZF5_DOCOC") + U_ITKEY( _cSerieNota ,"ZF5_SEROC") + U_ITKEY( StrZero(_nCodigo,6) ,"ZF5_CODIGO")))
                   Loop
                Else
                   Exit
                EndIf
             EndDo

             _oModelGrid:LoadValue('ZF5_CODIGO', StrZero(_nCodigo,6))
          EndIf
      Next _nI

      _aItOcorre := {}

      ZF5->(DBSetOrder(1)) // ZF5_FILIAL+ZF5_DOCOC+ZF5_SEROC

   EndIf

   If _nOperation == MODEL_OPERATION_INSERT
      //Valida registro duplicado
      _cQuery	:= " SELECT count(ZF5_FILIAL) AS CONTA "
      _cQuery  	+= " FROM " + RetSqlName("ZF5") + " ZF5"
      _cQuery  	+= " WHERE ZF5.ZF5_FILIAL = '" + xFilial("ZF5") + "'"
      _cQuery   += " AND ZF5.ZF5_DOCOC = '" + AllTrim(_oModelMaster:GetValue("ZF5_DOCOC")) + "'"
      If !Empty(AllTrim(_oModelMaster:GetValue("ZF5_SEROC")))
           _cQuery  += " AND ZF5.ZF5_SEROC = '" + AllTrim(_oModelMaster:GetValue("ZF5_SEROC")) + "'"
      EndIf
      _cQuery  	+= " AND ZF5.D_E_L_E_T_ = ' ' "
      cAlias:=GetNextAlias()
      MPSysOpenQuery( _cQuery , cAlias)
      If .not. (cAlias)->( Eof() )  .And.  (cAlias)->CONTA > 0
         Help( ,, 'Atenção',, 'Já existe registro com mesmo número de nota fiscal e transportador!' , 1, 0, .F. )
         (cAlias)->( DBCloseArea() )
         _lRet := .F.
         Break
      EndIf
      (cAlias)->( DBCloseArea() )
   EndIf

   If _nOperation == MODEL_OPERATION_INSERT .Or. _nOperation == MODEL_OPERATION_UPDATE

      // Valida se a carga foi entregue e se foi entrega parcial ou integral.
      If _oModelMaster:GetValue("ZF5_MERENT") == "S" .And. Empty(_oModelMaster:GetValue("ZF5_SITENT"))
         Help( ,, 'Atenção',, 'Para mercadorias assinaladas como Entregues, é obrigatório informar se a entrega foi Integral ou Parcial.' , 1, 0, .F. )
            _lRet := .F.
         Break
      EndIf

      If (_oModelMaster:GetValue("ZF5_MERENT") == "N" .Or. _oModelMaster:GetValue("ZF5_MERENT") == " ") .And. ! Empty(_oModelMaster:GetValue("ZF5_SITENT"))
         _oModelMaster:LoadValue("ZF5_SITENT"," ")
         U_ITMsg("A mercadoria foi assinalada como não entregue. Sendo assim, o conteúdo do campo Situação de Entrega (Integral/Parcial) foi removido.","Atenção",,2)
      EndIf

      //Validação de total de custos
      //Validação de custo representante/italac vs tipo de representante
      _cNotaFiscal:=_oModelMaster:GetValue("ZF5_DOCOC")
      _cSerie     :=_oModelMaster:GetValue("ZF5_SEROC")
      SF2->(DBSetOrder(1))

      For _nI := 1 To _oModelGrid:Length()

         _oModelGrid:GoLine(_nI)
         _cEstonado:= _oModelGrid:GetValue("ZF5_ESTONO")
         If _cEstonado = "S" .Or. _oModelGrid:IsDeleted() //SE ESTORNADO OU DELETADO NÃO LE
            Loop
         EndIf

         _dDataOcorr:= _oModelGrid:GetValue("ZF5_DTOCOR")
         _nValtransp:= _oModelGrid:GetValue('ZF5_CUSTOT')
         _nValtot   := _oModelGrid:GetValue('ZF5_CUSTO')
         _nValoco   := _oModelGrid:GetValue('ZF5_VLRTOT')
         _nValita   := _oModelGrid:GetValue('ZF5_CUSTOI')
         _nValrep   := _oModelGrid:GetValue('ZF5_CUSTOR')
         _nValcli   := _oModelGrid:GetValue('ZF5_CUSTOC')
         _nValter   := _oModelGrid:GetValue('ZF5_CUSTER')
         _nValemb   := _oModelGrid:GetValue('ZF5_VALEMB')
         _cCodigo   := AllTrim(Str(Val(_oModelGrid:GetValue('ZF5_CODIGO',_nI))))  // Código da ocorrência por nota
         _cTipoOcorr:= _oModelGrid:GetValue("ZF5_TIPOO")
         _cDtTran   :=  Posicione("ZFC",1,xFilial("ZFC")+_cTipoOcorr,"ZFC_DTTRAN") // 1 = ZFC_FILIAL+ZFC_CODIGO

         If _dDataOcorr > Date() .And. _cDtTran <> "F"
            Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ', Data da ocorrencia '+DToC(_dDataOcorr)+' não pode ser maior que Hoje.' , 1, 0 )
            _lRet := .F.
            Break
         EndIf

         SF2->(DBSeek(xFilial("SF2")+_cNotaFiscal+_cSerie))
         If _dDataOcorr < SF2->F2_EMISSAO
            Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ', Data da ocorrencia '+DToC(_dDataOcorr)+'não pode ser menor que emissao da NF: '+DToC(SF2->F2_EMISSAO) , 1, 0 )
            _lRet := .F.
            Break
         EndIf

         If _nvaltot <> (_nvaltransp+_nvalita+_nvalrep+_nvalcli+_nvalter+_nvalemb)
            Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Valor total da ocorrência deve ser igual à somatória dos custos Italac, ' + ;
                      ' cliente, representante, transportador, terceiros e embutido no frete ' , 1, 0, .F. )
            _lRet := .F.
            Break
         EndIf

         If _nvaloco <> (_nvaltransp+_nvalita+_nvalrep+_nvalcli+_nvalter)
            Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Custo da ocorrência deve ser igual à somatória dos custos Italac, ' + ;
                     ' cliente, representante, transportador, terceiros ' , 1, 0, .F. )
             _lRet := .F.
             Break
         EndIf

         If (_oModelGrid:GetValue('ZF5_TIPOC') == "V")  .And. Posicione("SA3",1,xFilial("SA3")+AllTrim(_oModelMaster:GetValue("ZF5_REPRES")),"A3_TIPO") <> "I"
             Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Tipo de Custo Vendedor Interno só pode ser preenchido para Vendedor Interno. ', 1, 0 )
             _lRet := .F.
             Break
         EndIf

         If (_oModelGrid:GetValue('ZF5_TIPOC') == "R")  .And. Posicione("SA3",1,xFilial("SA3")+AllTrim(_oModelMaster:GetValue("ZF5_REPRES")),"A3_TIPO") = "I"
             Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Tipo de Custo Representante Externo só pode ser preenchido para Representante Externo. ', 1, 0 )
             _lRet := .F.
             Break 
         EndIf

         If !_oModelGrid:IsDeleted() .And. (_oModelGrid:IsInserted(_nI) .Or. _oModelGrid:IsUpdated(_nI))
            ZF5->(DBSetOrder(4))
            ZF5->(DBSeek(xFilial("ZF5")+_cNotaFiscal+_cSerie+_oModelGrid:GetValue('ZF5_CODIGO')))
            _nValtotOld := ZF5->ZF5_CUSTO
            lAlterou := (_oModelGrid:IsInserted(_nI) .Or. (_oModelGrid:IsUpdated(_nI) .And. _nValtotOld <> _nValtot ))
            If _nValtot > 0 .And. lAlterou .And. Empty(_oModelGrid:GetValue("ZF5_CAUCUS") )
               Help( ,, 'Inclusao',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' -  Se tem Valor de custo o campo "Causador do Custo" deve ser informado.', 1, 0, .F. )
               _lRet := .F.
               Break
            EndIf
         EndIf

         If !_oModelGrid:IsDeleted() .And. _oModelGrid:IsInserted(_nI)
            ZFC->(DBSetOrder(1))
            If ZFC->(DBSeek(xFilial("ZFC")+_oModelGrid:GetValue("ZF5_TIPOO")))
               If ZFC->ZFC_PROTIT == "S"
                  If !(RetCodUsr() $ _cUsersHab) .And. _oModelGrid:GetValue("ZF5_DPRORR") > 0
                     _lRet := .F.
                     Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Usuário não tem permissão para usar este tipo de Ocorrencia.', 1, 0, .F. )
                     Break
                  EndIf
               EndIf
            EndIf
         EndIf

         If !_oModelGrid:IsDeleted() 
            ZFC->(DBSetOrder(1))
            If ZFC->(DBSeek(xFilial("ZFC")+_oModelGrid:GetValue("ZF5_TIPOO")))
               If ZFC->ZFC_OLREDI  == "S"
                  If Empty(_oModelGrid:GetValue("ZF5_OLRCOD")) .Or. Empty(_oModelGrid:GetValue("ZF5_OLRLOJ"))
                     U_ITMsg('Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Tipo de ocorrecia é de redirecionamento. (ZFC_OLREDI="S").','Atenção',;
                             "Informe o Codigo do operador logistico do redirecionamento.",,,,.T.)
                     _lRet := .F.
                     Break
                  EndIf
               Else
                  If !Empty(_oModelGrid:GetValue("ZF5_OLRCOD")) .Or. !Empty(_oModelGrid:GetValue("ZF5_OLRLOJ"))
                     U_ITMsg('Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Tipo de ocorrecia não é de redirecionamento. (ZFC_OLREDI<>"S").','Atenção',;
                             'O Codigo do operador logistico do redirecionamento não pode ser informado.',,,,.T.)
                      _lRet := .F.
                     Break
                  EndIf
               EndIf
            EndIf
         EndIf

      Next _nI

      _cfilold:=cfilant

      //Validação de custo de devolução
      For _nI := 1 To _oModelGrid:Length()

         _oModelGrid:GoLine(_nI)
         _cEstonado:= _oModelGrid:GetValue("ZF5_ESTONO")
         If _cEstonado = "S" .Or. _oModelGrid:IsDeleted() //SE ESTORNADO OU DELETADO NÃO LE
            Loop
         EndIf

         _lnotadev := (_oModelGrid:GetValue('ZF5_DEVOL'  ) == "S" )
         _ctipoc   :=  _oModelGrid:GetValue('ZF5_TIPOC'  )
         _cdvitens :=  _oModelGrid:GetValue('ZF5_DVITEM' )

         //Soma valores de itens selecionados para devolução
         If _lnotadev .And. !Empty(_ctipoc) .And. !Empty(_cdvitens)

            _cforn := AllTrim(_oModelMaster:GetValue('ZF5_CLIENT'))
            _clojaf := AllTrim(_oModelMaster:GetValue('ZF5_LOJA'))

            //Localiza nota de devolução
            SF1->(DBSetOrder(1))
            If SF1->(DBSeek(xFilial("SF1")+_oModelGrid:GetValue('ZF5_DOCDEV' )+_oModelGrid:GetValue('ZF5_SERDEV')+_cforn+_clojaf))

               SD1->(DBSetOrder(1))
               SD1->(DBSeek(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA))

               _ntotal := 0

               While SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA == SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA

                  If SD1->D1_ITEM $ _cdvitens

                     _ntotal += SD1->D1_TOTAL

                  EndIf

                  SD1->(DBSkip())

               EndDo

            Else

               Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + " - Não foi localizada nota de devolução - Verifique o item " + StrZero(_nI,3), 1, 0 )
               _lRet := .F.
               Break

            EndIf

            If _ntotal != _oModelGrid:GetValue('ZF5_CUSTO' ) .And. SuperGetMV("IT_OCVALDE",.T.,.F.);
                  .And.  Posicione("ZFD",1,xFilial("ZFD")+_oModelGrid:GetValue('ZF5_STATUS' ),"ZFD_STATUS") == "E"

               Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + " - Custo da ocorrência diverge da nota de devolução! - Verifique o item " + StrZero(_nI,3), 1, 0 )

               _lRet := .F.
               Break

            EndIf


         ElseIf !Empty(_cdvitens)

            Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + " - Selecione tipo de custo e marque a ocorrência como devolução para indicar nota de devolução  "  , 1, 0 )
            _lRet := .F.
            Break

         EndIf

      Next _nI

      //Validação de nota de débito e pedido de descarte
      _cNotaFiscal := _oModelMaster:GetValue("ZF5_DOCOC")
      _cSerie      := _oModelMaster:GetValue("ZF5_SEROC")
      For _nI := 1 To _oModelGrid:Length()

          _oModelGrid:GoLine(_nI)
          _cEstonado:= _oModelGrid:GetValue("ZF5_ESTONO")
          If _cEstonado = "S" .Or. _oModelGrid:IsDeleted() //SE ESTORNADO OU DELETADO NÃO LE
             Loop
          EndIf
          _nvaltransp  := _oModelGrid:GetValue('ZF5_CUSTOT',_nI)    //Custo transportador transportador
          _cndebit     := _oModelGrid:GetValue('ZF5_NDEBIT',_nI)   // Nota de debito
          _cgerdev     := _oModelGrid:GetValue('ZF5_GERDEV',_nI)   // Gera Pedido de descarte
          _cpeddev     := _oModelGrid:GetValue('ZF5_PEDDEV',_nI)   // Pedido de descarte
          _cdocdev     := _oModelGrid:GetValue('ZF5_DOCDEV',_nI)   // Documento de devolução
          _cserdev     := _oModelGrid:GetValue('ZF5_SERDEV',_nI)   // Série de documento de devolução
          _cdvitem     := _oModelGrid:GetValue('ZF5_DVITEM',_nI)   // Itens do documento de devolução
          _ctipocus    := _oModelGrid:GetValue('ZF5_TIPOC',_nI)   // Tipo de custo
          _cStatus     := _oModelGrid:GetValue('ZF5_STATUS',_nI)   // Status da ocorrência
          _cCodigo     := AllTrim(Str(Val(_oModelGrid:GetValue('ZF5_CODIGO',_nI))))  // Código da ocorrência por nota
          _ccodter     := _oModelGrid:GetValue('ZF5_FORTER',_nI) //Fornecedor terceiro
          _clojter     := _oModelGrid:GetValue('ZF5_LOJTER',_nI) //Loja terceiro
          _nvalterc    := _oModelGrid:GetValue('ZF5_CUSTER',_nI) //Custo terceiro
          _ddtfinal    := _oModelGrid:GetValue('ZF5_DTFIN',_nI)
          _cmotcus     := _oModelGrid:GetValue('ZF5_MOTCUS',_nI)
          _cTipoO      := _oModelGrid:GetValue('ZF5_TIPOO',_nI)   // Tipo de ocorrência
          _cMotivo     := _oModelGrid:GetValue('ZF5_MOTIVO',_nI)  // Motivo da ocorrência
          _ctransp     := _oModelGrid:GetValue("ZF5_TRANSP",_nI)
          _clojat      := _oModelGrid:GetValue("ZF5_LJTRAN",_nI)

          If Posicione("ZFD",1,xFilial("ZFD")+_cStatus,"ZFD_STATUS") == "E"
             //Posiciona no registro gravado no banco para comparar
             ZF5->(DBSetOrder(4))
             If !(ZF5->(DBSeek(xFilial("ZF5")+_cNotaFiscal+_cserie+_oModelGrid:GetValue('ZF5_CODIGO',_nI)))) .And. _cndebit == "S"
                Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Para nota de débito, inclua a ocorrência com status pendende e depois altere para status encerrado!' , 1, 0 )
                _lRet := .F.
                Break

             ElseIf !(ZF5->(DBSeek(xFilial("ZF5")+_cNotaFiscal+_cserie+_oModelGrid:GetValue('ZF5_CODIGO',_nI)))) .And. _cgerdev == "S"
                Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Para pedido de descarte, inclua a ocorrência com status pendende e depois altere para status encerrado!' , 1, 0 )
                _lRet := .F.
                Break
             ElseIf Upper(AllTrim(ZF5->ZF5_MOTCUS)) != Upper(AllTrim(_cmotcus))
                //Help( ,, 'Atenção',, 'Ocorrência ' + _cCodigo + ' - Salve o motivo de custo antes de encerrar a ocorrência!' , 1, 0 )
                //ITmsg(_cMens,_ctitu,_csolu,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes)
                U_ITMsg('Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Salve o motivo de custo antes de encerrar a ocorrência!','Atenção',;
                        "Texto: ["+AllTrim(ZF5->ZF5_MOTCUS)+"] gravado  diferente do digitado ["+AllTrim(_cmotcus)+"]",,,,.T.)
                _lRet := .F.
                Break
             EndIf
          EndIf

          //Valida relação entre campos gera devolução e gera pedido de descarte
          If _oModelGrid:GetValue('ZF5_GERDEV',_nI ) == "S" .And. _oModelGrid:GetValue('ZF5_DEVOL',_nI ) != "S"
             Help( ,, "Atenção",, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + " - Para gerar pedido de descarte precisa ser ocorrência de devolução!" , 1, 0 )
             _lRet := .F.
             Break
          EndIf

          //Valida se está incluindo nota com custo terceiro ou transportador sem nota de débito
          If (_nvalterc > 0 .Or. _nvaltransp > 0) .And. _cndebit != "S"
              If Posicione("ZFD",1,xFilial("ZFD")+_cStatus,"ZFD_STATUS") == "E"  .And. _ddtfinal > SToD("20190103")
                 Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Ocorrência com custo de transportador/terceiro só pode ser encerrada com geração de nota de débito de transporte!' , 1, 0 )
                 _lRet := .F.
                 Break
               EndIf
          EndIf

          //Valida se itens de devolução não foram usados já
          If _nOperation == MODEL_OPERATION_UPDATE
             //Posiciona no registro gravado no banco para comparar
             ZF5->(DBSetOrder(4))
             ZF5->(DBSeek(xFilial("ZF5")+_cNotaFiscal+_cserie+_oModelGrid:GetValue('ZF5_CODIGO')))

             //SÓ VALIDA SE ESTÁ ENCERRANDO
             If Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_STATUS") != "E" .AND.;
                Posicione("ZFD",1,xFilial("ZFD")+_oModelGrid:GetValue('ZF5_STATUS'),"ZFD_STATUS") == "E"

               //Só valida se tem conteúdo na ZF5_DVITEM
               If !Empty(_oModelGrid:GetValue('ZF5_DVITEM'))

                  //Valida se está em outra linha da ocorrência atual
                  _aitens := Strtokarr2( _oModelGrid:GetValue('ZF5_DVITEM',_nI), '/')

                  For _nk := 1 to _oModelGrid:Length()
                      _oModelGrid:GoLine(_nk)
                      _cEstonado:= _oModelGrid:GetValue("ZF5_ESTONO",_nk)
                      If _cEstonado = "S" .Or. _oModelGrid:IsDeleted() //SE ESTORNADO OU DELETADO NÃO LE
                         Loop
                      EndIf
                      If _oModelGrid:GetValue('ZF5_DOCDEV',_nk) == _oModelGrid:GetValue('ZF5_DOCDEV',_nI)
                         For _nj := 1 to Len(_aitens)
                            If _aitens[_nj] $ _oModelGrid:GetValue('ZF5_DVITEM',_nk) .And. _nk != _nI .And. !Empty(_aitens[_nj])
                               Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Item de devolução já utilizado na linha ' + StrZero(_nk,3) + '!' , 1, 0 )
                               _lRet := .F.
                               Break
                            EndIf
                         Next _nj
                      EndIf
                  Next _nk

                  _oModelGrid:GoLine(_nI)

                  //Valida se está em outra linha da base de dados
                  _cQry := " SELECT ZF5_DOCOC, ZF5_DVITEM FROM "+RetSqlName("ZF5")+" ZF5 "
                  _cQry += " WHERE ZF5.D_E_L_E_T_ = ' ' AND ZF5_FILIAL = '"+xFilial("ZF5")+"' "
                  _cQry += " AND ZF5_DOCDEV = '" + AllTrim(_oModelGrid:GetValue('ZF5_DOCDEV',_nI)) + "' "
                  _cQry += " AND ZF5_CLIENT = '" + AllTrim(_oModelMaster:GetValue('ZF5_CLIENT')) + "' "
                  _cQry += " AND ZF5_LOJA = '" + AllTrim(_oModelMaster:GetValue('ZF5_LOJA')) + "' "
                  _cQry += " AND ZF5_DOCOC <> '" + AllTrim(_oModelMaster:GetValue('ZF5_DOCOC')) + "' "
                  _cQry := ChangeQuery(_cQry)
                  cAlias:=GetNextAlias()
                  MPSysOpenQuery( _cQry , cAlias )

                  While (cAlias)->(!Eof())
                     For _nj := 1 to Len(_aitens)
                        If _aitens[_nj] $ (cAlias)->ZF5_DVITEM .And. !Empty(_aitens[_nj])
                           Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Item de devolução já utilizado em ocorrência da nota  ' + (cAlias)->ZF5_DOCOC + '!' , 1, 0 )
                           _lRet := .F.
                           Break
                        EndIf
                     Next _nj
                     (cAlias)->(DBSkip())
                  EndDo
                  (cAlias)->(DBCloseArea())
               EndIf
            EndIf
         EndIf

         //Valida se está tentando alterar campos proibidos em uma ocorrência encerrada com título de débito de transporte
         If _nOperation == MODEL_OPERATION_UPDATE

            //Posiciona no registro gravado no banco para comparar
            ZF5->(DBSetOrder(4))
            ZF5->(DBSeek(xFilial("ZF5")+_cNotaFiscal+_cserie+_oModelGrid:GetValue('ZF5_CODIGO')))
            If Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_STATUS") == "E"

               If _oModelGrid:IsDeleted()
                  Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + 'Para deletar a linha, reabra ocorrência primeiro!' , 1, 0 )
                  _lRet := .F.
                  Break
               EndIf

               If _cndebit != ZF5->ZF5_NDEBIT
                  Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6)+ ' - Para alterar geração de nota de débito reabra ocorrência primeiro!' , 1, 0 )
                  _lRet := .F.
                  Break
               EndIf

               If _cpeddev != ZF5->ZF5_PEDDEV .Or. _cgerdev != ZF5->ZF5_GERDEV
                  Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Para alterar pedido de descarte reabra ocorrência primeiro!' , 1, 0 )
                  _lRet := .F.
                  Break
               EndIf

               If _cgerdev == "S" .And. (_cdocdev != ZF5->ZF5_DOCDEV .Or. _cserdev != ZF5->ZF5_SERDEV .Or. _cdvitem != ZF5->ZF5_DVITEM)
                  Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Para alterar dados de devolução reabra ocorrência primeiro!' , 1, 0 )
                  _lRet := .F.
                  Break
               EndIf

               If ZF5->ZF5_NDEBIT == "S" .And. _ctipocus != ZF5->ZF5_TIPOC
                  Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Para alterar tipo de custo com nota de débito reabra ocorrência primeiro!' , 1, 0 )
                  _lRet := .F.
                  Break
               EndIf

               If ZF5->ZF5_NDEBIT == "S" .And. _ctipocus == "T" .And.  _nvaltransp != ZF5->ZF5_CUSTOT
                   Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Para alterar valor de custo com nota de débito reabra ocorrência primeiro!' , 1, 0 )
                   _lRet := .F.
                   Break
               EndIf

               If ZF5->ZF5_NDEBIT == "S" .And. _ctipocus == "3" .And.  _nvalterc != ZF5->ZF5_CUSTER
                   Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Para alterar valor de custo com nota de débito reabra ocorrência primeiro!' , 1, 0 )
                   _lRet := .F.
                   Break
               EndIf

            EndIf
         EndIf

         //Valida se está tentando reabrir uma ocorrência com título de débito de transporte ou pedido de descarte
         //Exclui título se possível
         If  _nOperation == MODEL_OPERATION_UPDATE .And. !_oModelGrid:IsDeleted()

             //Posiciona no registro gravado no banco para comparar
             ZF5->(DBSetOrder(4))
             ZF5->(DBSeek(xFilial("ZF5")+_cNotaFiscal+_cserie+_oModelGrid:GetValue('ZF5_CODIGO',_nI)))

             //VALIDA SE JÁ EXISTE PEDIDO DE DESCARTE
             If Posicione("ZFD",1,xFilial("ZFD")+_cStatus,"ZFD_STATUS") != "E" .And. Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_STATUS") == "E"

                SC5->(DBSetOrder(1))
                If SC5->(DBSeek(xFilial("SC5")+_cpeddev))
                   If U_ITMsg("Existe pedido de descarte para essa ocorrência. Pedido será excluido com a reabertura da ocorrência. Deseja continuar?",;
                              "Atenção","Pedido: "+xFilial("SC5")+" "+_cpeddev+' - Ocorrência: ' + StrZero(Val(_cCodigo),6),2,2,2)
                      //Tenta fazer exclusão do pedido de descarte
                      _lRet := AOMS003DP()
                      If !_lRet
                         Break
                      EndIf
                   Else
                      Help( ,, 'Atenção',, 'Processo cancelado' , 1, 0 )
                      _lRet := .F.
                      Break
                   EndIf
                Else
                  _oModelGrid:LoadValue('ZF5_PEDDEV',_nI)
                  _cpeddev := ' '
                EndIf
             EndIf //VALIDA SE JÁ EXISTE PEDIDO DE DESCARTE

             If Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_STATUS") == "E"  .And.  Posicione("ZFD",1,xFilial("ZFD")+_cStatus,"ZFD_STATUS") != "E"
                _cfilold := cfilant
                //Se For nota de faturamento de um troca nota muda para a filial de carregamento para incluir a nota de débito
                SF2->(DBSetOrder(1))
                If SF2->(DBSeek(xFilial("SF2")+_cNotaFiscal+_cSerie))
                   SC5->(DBSetOrder(1))
                   If SC5->(DBSeek(xFilial("SC5")+SF2->F2_I_PEDID))
                      If SC5->C5_I_TRCNF = "S" .And. SC5->C5_I_FLFNC != SC5->C5_FILIAL
                         cfilant := SC5->C5_I_FLFNC
                      EndIf
                   EndIf
                EndIf

                _cFornece:=""
                _cLoja:=""
                If ZF5->ZF5_TIPOC == "T"
                   _cFornece := AllTrim(ZF5->ZF5_TRANSP)
                   _cLoja    := ZF5->ZF5_LJTRAN
                ElseIf ZF5->ZF5_TIPOC == "3"
                   _cFornece := ZF5->ZF5_FORTER
                   _cLoja    := ZF5->ZF5_LOJTER
                EndIf

               If !Empty(ZF5->ZF5_CHVNDT)
                  If Len(AllTrim(ZF5->ZF5_CHVNDT)) = Len(SE2->E2_FILIAL+SE2->E2_PREFIXO+SE2->E2_NUM)//CHAVE SEM PARCELA
                     _cSeekSE2:=ZF5->ZF5_CHVNDT + "01" + "NDF"+_cFornece+_cLoja//A chave e o cfilant já estam com a filai certa
                  Else//CHAVE COM PARCELA - NOVA
                     _cSeekSE2:=ZF5->ZF5_CHVNDT + "NDF"+_cFornece+_cLoja//A chave e o cfilant já estam com a filai certa
                  EndIf
                  _cMostra:=_cSeekSE2
               Else//CHAVE ANTIGA
                  _cSeekSE2:=xFilial("SE2")+"NDT"+SubStr(_cNotaFiscal,2,8) + StrZero(Val(_cCodigo),6) + "01" + "NDF"//o cfilant já na filiaa certa
               EndIf

               SE2->(DBSetOrder(1)) // E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
               If SE2->(DBSeek(_cSeekSE2))
                  If Empty(ZF5->ZF5_CHVNDT)
                     _cMostra:=_cSeekSE2+SE2->E2_FORNECE+SE2->E2_LOJA
                  EndIf
                  If U_ITMsg("Existe título de débito de transporte para essa ocorrência. Título será excluido com a reabertura da ocorrência. Deseja continuar?",;
                              "Atenção","Chave Titulo: "+_cMostra+' - Ocorrência: ' + StrZero(Val(_cCodigo),6),2,2,2)
                     _lerro := !(AOMS003DT( ZF5->(RECNO()),_oModelGrid ))//EXCLUI TÍTULO DE DÉBITO
                     If _lerro
                        // JÁ DÁ MENSAGEM DE ERRO DENTRO DA FUNÇÃO AOMS003DT ()
                        //Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Erro ao excluir título de nota de débito, ocorrência não será salva/apagada.' , 1, 0 )
                        _lRet := .F.
                        cfilant := _cfilold
                        Break
                     EndIf
                  Else
                      Help( ,, 'Atenção',, 'Alteração cancelada!' , 1, 0 )
                      _lRet := .F.
                      cfilant := _cfilold
                      Break
                  EndIf
               EndIf
               cfilant := _cfilold

            EndIf

         EndIf

             If !(_oModelGrid:IsDeleted())

               //Só aceita nota de débito para custo de terceiro ou transportador
               If _cndebit == "S" .And. _ctipocus != "T" .And. _ctipocus != "3"
                   Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Somente gera nota de débito para custo transportador ou terceiro!' , 1, 0 )
                   _lRet := .F.
                   Break
               EndIf
               //Valida consistência de campos valor transportador
               If _cndebit == "S" .And. _nvaltransp <= 0 .And. _ctipocus == "T"
                  Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Para ter nota de débito é preciso indicar custo para transportador!' , 1, 0 )
                  _lRet := .F.
                  Break
               EndIf
               //Valida consistência de campos valor terceiro
               If _cndebit == "S" .And. _nvalterc <= 0 .And. _ctipocus == "3"
                  Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Para ter nota de débito é preciso indicar custo para terceiro!' , 1, 0 )
                  _lRet := .F.
                  Break
               EndIf

               //Verifica se a ocorrencia de frete possui uma natureza específica para gerar o titulo no Financeiro
               If !Empty(AllTrim(_cTipoO))
                  _cNaturOF := Posicione("ZFC",1,xFilial("ZFC")+_cTipoO,"ZFC_NATUR")
               Else
                  _cNaturOF := ""
               EndIf

               If !Empty(AllTrim(_cNaturOF))
                  _cnatureza := _cNaturOF
               Else
                  If _ctipocus == "T"  //Verificar aqui se é custo transportador ou custo terceiro
                     _cnatureza := SuperGetMV("IT_NDNATUR",.T.,"112021    ")
                  ElseIf _ctipocus == "3"
                     _cnatureza := SuperGetMV("IT_NTNATUR",.T.,"112022    ")
                  EndIf
               EndIf

               //SE STATUS ESTÁ ENCERRADO, VALIDA SE JÁ EXISTE PEDIDO DE DESCARTE
               If Posicione("ZFD",1,xFilial("ZFD")+_cStatus,"ZFD_STATUS") == "E" .And. _cgerdev == "S";
                       .And. Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_STATUS")  != "E"

                  //Posiciona no registro gravado no banco para comparar
                  ZF5->(DBSetOrder(4))
                  ZF5->(DBSeek(xFilial("ZF5")+_cNotaFiscal+_cserie+_oModelGrid:GetValue('ZF5_CODIGO')))
                  SC5->(DBSetOrder(1))

                  If !(SC5->(DBSeek(xFilial("SC5")+_cpeddev)))

                     If !U_ITMsg("Encerramento de ocorrência irá gerar pedido de descarte, confirma?","Atenção",'Ocorrência ' + StrZero(Val(_cCodigo),6),2,2,2)
                        Help( ,, 'Atenção',, 'Processo cancelado pelo usuário.' , 1, 0 )
                        _lRet := .F.
                        Break
                     EndIf

                     //LOCALIZA DOCUMENTO DE DEVOLUÇÃO
                     SF1->(DBSetOrder(1))
                     If SF1->(DBSeek(xFilial("SF1")+_cdocdev+_cserdev+ZF5->ZF5_CLIENT+ZF5->ZF5_LOJA+"D"))
                        SD1->(DBSetOrder(1))
                        If SD1->(DBSeek(xFilial("SD1")+_cdocdev+_cserdev+ZF5->ZF5_CLIENT+ZF5->ZF5_LOJA))
                        _aItensPV := {}
                        _njk := 0
                        While SF1->F1_FILIAL == SD1->D1_FILIAL .AND.;
                                 SF1->F1_DOC == SD1->D1_DOC .AND.;
                                 SF1->F1_FORNECE == SD1->D1_FORNECE .AND.;
                                 SF1->F1_LOJA == SD1->D1_LOJA .AND.;
                                 SF1->F1_SERIE == SD1->D1_SERIE

                           If SD1->D1_ITEM $ _cdvitem

                              _njk++
                              aAdd( _aItensPV , { { "C6_FILIAL"  , cfilant	   				    ,Nil},;
                                                  { "C6_ITEM"    , StrZero(_njk,2)				,Nil},;
                                                  { "C6_PRODUTO" , SD1->D1_COD  				,Nil},;
                                                  { "C6_UM"    	 , SD1->D1_UM				    ,Nil},;
                                                  { "C6_QTDVEN"  , SD1->D1_QUANT   				,Nil},;
                                                  { "C6_UNSVEN"  , SD1->D1_QTSEGUM				,Nil},;
                                                  { "C6_LOCAL"   , SuperGetMV("IT_LOCDESC",.T.,"31")	,nil},;
                                                  { "C6_PRCVEN"  , SD1->D1_TOTAL/SD1->D1_QUANT	,Nil},;
                                                  { "C6_VALOR"   , SD1->D1_TOTAL              	,Nil},;
                                                  { "C6_I_DEVFN" , SD1->D1_FORNECE           	,Nil},;
                                                  { "C6_I_DEVLJ" , SD1->D1_LOJA              	,Nil},;
                                                  { "C6_I_DEVDO" , SD1->D1_DOC               	,Nil},;
                                                  { "C6_I_DEVSE" , SD1->D1_SERIE              	,Nil},;
                                                  { "C6_I_DEVIT" , SD1->D1_ITEM               	,Nil},;
                                                  { "C6_ENTREGA" , date()+100      	            ,Nil}} )

                           EndIf

                           SD1->(DBSkip())

                        EndDo

                     Else

                        Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Não foi possível localizar nota de devolução da ocorrência' , 1, 0 )
                        _lRet := .F.
                        Break

                        EndIf

                     Else

                        Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Não foi possível localizar nota de devolução da ocorrência' , 1, 0 )
                        _lRet := .F.
                        Break

                     EndIf

                     If Len(_aItensPV) == 0

                        Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Não foi possível localizar itens da nota de devolução da ocorrência' , 1, 0 )
                        _lRet := .F.
                        Break

                     EndIf

                  //Carrega cliente e loja da filial atual
                  ZZM->(DBSetOrder(1))
                  If !(ZZM->(DBSeek(xFilial("ZZM")+cfilant)))

                     Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Não foi possível localizar filial atual no cadastro de filiais (ZZM)' , 1, 0 )
                     _lRet := .F.
                     Break

                  EndIf

                  SA1->(DBSetOrder(3))
                  If !(SA1->(DBSeek(xFilial("SA1")+ZZM->ZZM_CGC)))

                     Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Não foi possível localizar filial atual no cadastro de clientes com cgc ' + ZZM->ZZM_CGC   , 1, 0 )
                     _lRet := .F.
                     Break

                  EndIf

                  If !_lJob
                     _cCodUsu	:= FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
                  Else
                     _cCodUsu	:= "SISTEMA"
                  EndIf

                  //Cria pedido de descarte
                  aCabec := { { "C5_FILIAL"     , cfilant	                                                , Nil },;
                              { "C5_TIPO"   	, "N"		                                                   , Nil },;
                              { "C5_CLIENTE"	, SA1->A1_COD	                                             , Nil },;
                              { "C5_LOJACLI"	, SA1->A1_LOJA	                                             , Nil },;
                              { "C5_TIPOCLI"	, SA1->A1_TIPO	 	                                          , Nil },;
                              { "C5_CONDPAG"	, '001'													 	            , Nil },;
                              { "C5_VEND1"      , SA1->A1_VEND												            , Nil },;
                              { "C5_VEND2"      , Posicione('SA3',1,xFilial('SA3')+SA1->A1_VEND,'A3_SUPER')	, Nil },;
                              { "C5_VEND3"      , SA3->A3_GEREN											            , Nil },;
                              { "C5_EMISSAO"	, Date()	                                                   , Nil },;
                              { "C5_TABELA" 	, ''														               , Nil },;
                              { "C5_MENNOTA"	, 'Descarte de devolução'							               , Nil },;
                              { "C5_TPFRETE"	, 'C'														               , Nil },;
                              { "C5_I_OBPED"    , 'Descarte devolução - Oc frete NF Venda ' + ZF5->ZF5_DOCOC+"/"+ZF5->ZF5_SEROC, Nil },;
                              { "C5_I_OPER"     , SuperGetMV("IT_TPOPDES",.T.,"22")			   			         , Nil },;
                              { "C5_TRANSP"     , ''														               , Nil },;
                              { "C5_I_DTENT"    ,  date()+100          										         , Nil },;
                              { "C5_I_CDUSU"    ,  _cCodUsu          										         , Nil },;
                              { "C5_I_AGEND"    , "I"	                                                      , Nil }}

                  lMSErroAuto := .F.

                  FWMsgRun(, { || MSExecAuto( {|x,y,z| Mata410(x,y,z) } , aCabec , _aItensPV , 3 )},"Aguarde...","Criando pedido de descarte...")

                  If lMsErroAuto

                     MostraErro()
                     Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Não foi possível gerar o pedido de descarte' , 1, 0 )
                              _lRet := .F.
                     Break

                  Else

                     _oModelGrid:LoadValue('ZF5_PEDDEV',SC5->C5_NUM)
                     _cpeddev := SC5->C5_NUM
                     U_ITMsg("Criado pedido de descarte " + SC5->C5_NUM,"Atenção",'Ocorrência ' + StrZero(Val(_cCodigo),6),3)

                  EndIf

               EndIf

            EndIf

            //IDENTIFICA E VALDIA FORNECEDOR DO TÍTULO A PAGAR COMO TRANSPORTADOR OU TERCEIRO
            If _ctipocus == "T"
               If Empty(_ctransp)
                  Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Não há transportador vinculado à nota, use custo de terceiros e indique o fornecedor' , 1, 0 )
                  _lRet := .F.
                  Break
               EndIf
               _cFornece := AllTrim(_ctransp)
               _cLoja := _cLojat
               _cindice := xFilial("SA2")+AllTrim(_cFornece)+_cLojat
               _nvalortit := _nvaltransp
            ElseIf _ctipocus == "3"
               _cFornece := _ccodter
               _cLoja := _clojter
               _cindice := xFilial("SA2")+AllTrim(_cFornece)+AllTrim(_cLoja)
               _nvalortit := _nvalterc
            EndIf

            SA2->(DBSetOrder(1))
            If _ctipocus == "T" .Or. _ctipocus == "3"
               If !SA2->(DBSeek(_cindice))
                  Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Fornecedor para geração de título de nota de débito não localizado.' , 1, 0 )
                  _lRet := .F.
                  Break
               Else
                       If SA2->A2_MSBLQL == '1'
                          Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Erro ao gravar título de nota de débito, ocorrência não será salva. Fornecedor informado ' + AllTrim(_cFornece) + " - " + AllTrim(_cLoja) + ' encontra-se Bloqueado ou Inativo no cadastro de Fornecedores do Sistema!' , 1, 0 )
                       _lBloq := .T.
                       _lRet := .F.
                       cfilant := _cfilold
                       Break
                     EndIf
                     _cLoja:=SA2->A2_LOJA
               EndIf
             EndIf

            //SE STATUS ESTÁ ENCERRADO, VALIDA SE JÁ EXISTE GERAÇÃO DE TÍTULO DE NOTA DE DÉBITO ************************************
            If Posicione("ZFD",1,xFilial("ZFD")+_cStatus,"ZFD_STATUS") == "E" .And. _cndebit == "S";
                     .And. Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_STATUS")  != "E"

               If !Empty(ZF5->ZF5_CHVNDT)
                  If Len(AllTrim(ZF5->ZF5_CHVNDT)) = Len(SE2->E2_FILIAL+SE2->E2_PREFIXO+SE2->E2_NUM)//CHAVE SEM PARCELA
                     _cSeekSE2:=ZF5->ZF5_CHVNDT + "01" + "NDF"+_cFornece+_cLoja//A chave e o cfilant já estam com a filai certa
                  Else//CHAVE COM PARCELA - NOVO
                     _cSeekSE2:=ZF5->ZF5_CHVNDT + "NDF"+_cFornece+_cLoja//A chave e o cfilant já estam com a filai certa
                  EndIf
                  _cMostra:=_cSeekSE2
               Else
                  _cSeekSE2:=xFilial("SE2")+"NDT"+SubStr(_cNotaFiscal,2,8) + _cCodigo + "01" + "NDF"
               EndIf
               SE2->(DBSetOrder(1))
               If SE2->(DBSeek(_cSeekSE2))
                  If (_ctipocus == "T" .And. SE2->E2_VALOR != _nvaltransp) .Or. (_ctipocus == "3" .And. SE2->E2_VALOR != _nvalterc)
                     If Empty(ZF5->ZF5_CHVNDT)
                        _cMostra:=_cSeekSE2+SE2->E2_FORNECE+SE2->E2_LOJA
                     EndIf
                     //Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Já existe título com valor diferente: R$ '+AllTrim(TRANS(SE2->E2_VALOR,'@E 999,999,999,999.99'))+'. Reabra a ocorrência ou título e encerre novamente para alterar valor.' , 1, 0 )
                     U_ITMsg("Chave Titulo: "+_cMostra+' - Ocorrência: ' + StrZero(Val(_cCodigo),6) + '. Já existe título com valor diferente: R$ '+AllTrim(TRANS(SE2->E2_VALOR,'@E 999,999,999,999.99')),'Atenção!',"Reabra a ocorrência ou título e encerre novamente para alterar valor.",,,,.T.)
                     _lRet := .F.
                     Break
                  EndIf
               Else
                  lMsErroAuto := .F.
                  _cfilold := cfilant
                  //Se For nota de faturamento de um troca nota muda para a filial de carregamento para incluir a nota de débito
                  SF2->(DBSetOrder(1))
                  If SF2->(DBSeek(xFilial("SF2")+_cNotaFiscal+_cSerie))
                     SC5->(DBSetOrder(1))
                     If SC5->(DBSeek(xFilial("SC5")+SF2->F2_I_PEDID))
                        If SC5->C5_I_TRCNF = "S" .And. SC5->C5_I_FLFNC != SC5->C5_FILIAL
                           cfilant := SC5->C5_I_FLFNC
                        EndIf
                     EndIf
                  EndIf

                   // GERAÇÃO DO NUMERO DO TITULO POR PARCELA 
                  // ZF5_CHVNDT
                  _cNewParcela:="01"
                  SE2->(DBSetOrder(1))
                  _cSeekSE2:=xFilial("SE2")+"NDT"+SubStr(_cNotaFiscal,1,Len(SE2->E2_NUM)) + _cNewParcela  + "NDF"+AllTrim(_cFornece)+_cLoja
                  While SE2->(DBSeek(_cSeekSE2))
                     _cNewParcela:=Soma1(_cNewParcela)
                     _cSeekSE2:=xFilial("SE2")+"NDT"+SubStr(_cNotaFiscal,1,Len(SE2->E2_NUM)) + _cNewParcela + "NDF"+AllTrim(_cFornece)+_cLoja
                  EndDo
                  // ZF5_CHVNDT
                  // GERAÇÃO DO NUMERO DO TITULO POR PARCELA
                  //Definição de vencimento
                  If day(date()) < 8
                      _dvencto := SToD(AllTrim(Str(year(date())))+AllTrim(StrZero(month(date()),2))+"08")
                  ElseIf day(date()) > 7 .And.  day(date()) < 23
                      _dvencto := SToD(AllTrim(Str(year(date())))+AllTrim(StrZero(month(date()),2))+"23")
                  ElseIf day(date()) >= 23
                     If month(date()) == 12
                         _dvencto := SToD(AllTrim(Str(year(date())+1))+"0108")
                      Else
                          _dvencto := SToD(AllTrim(Str(year(date())))+AllTrim(StrZero(month(date())+1,2))+"08")
                      EndIf
                  EndIf

                  _cmens := 'Ocorrência ' + StrZero(Val(_cCodigo),8) + " - "
                  _cmens += "Título " + cfilant + "/" +  _cNotaFiscal +"-"+ _cNewParcela + " contra " + SA2->A2_COD+"/"+SA2->A2_LOJA+" - "+ AllTrim(SA2->A2_NREDUZ) + "  "
                  _cmens += "no valor de R$ " + transform(_nvalortit,"@E 999,999.99") + " com vencimento em " + DToC(_dvencto) + "."

                  If !U_ITMsg("Encerramento de ocorrência irá gerar título de débito de transporte, confirma?","Atenção",_cmens,2,2,2)
                       Help( ,, 'Atenção',, 'Processo cancelado pelo usuário.' , 1, 0 )
                      _lRet := .F.
                      cfilant := _cfilold
                      Break
                  EndIf

                  If _lBloq
                     _lRet := .F.
                     cfilant := _cfilold
                     Break
                  Else
                     _aAutoSE2 := {}
                     aAdd( _aAutoSE2 , { "E2_PREFIXO"	, "NDT"								     , nil } )
                     aAdd( _aAutoSE2 , { "E2_NUM"		, SubStr(_cNotaFiscal,1,Len(SE2->E2_NUM)), nil } )
                     aAdd( _aAutoSE2 , { "E2_PARCELA"	, _cNewParcela					         , nil } )
                     aAdd( _aAutoSE2 , { "E2_TIPO"		, "NDF"								     , nil } )
                     aAdd( _aAutoSE2 , { "E2_NATUREZ"	, _cnatureza			                 , nil } )
                     aAdd( _aAutoSE2 , { "E2_FORNECE"	, AllTrim(_cfornece)	                 , nil } )
                     aAdd( _aAutoSE2 , { "E2_LOJA"		, AllTrim(_cloja)	                     , nil } )
                     aAdd( _aAutoSE2 , { "E2_EMISSAO"	, Date()			                     , nil } )
                     aAdd( _aAutoSE2 , { "E2_VENCTO"	, _dvencto	                             , nil } )
                     aAdd( _aAutoSE2 , { "E2_VALOR"     , _nvalortit		                     , nil } )
                     aAdd( _aAutoSE2 , { "E2_HIST"		, "Custo de ocorrência de frete " + _cCodigo + "-" + AllTrim(ZF5->ZF5_MOTCUS) , Nil } )
                     aAdd( _aAutoSE2 , { "E2_DATALIB"	, Date()			                     , nil } )
                     aAdd( _aAutoSE2 , { "E2_USUALIB"	, cUserName			                     , nil } )

                     _nModAux	:= nModulo
                     _cModAux	:= cModulo
                     nModulo	:= 6
                     cModulo	:= "FIN"
                     _cAOMS074Vld:=""
                     _cAOMS074   :="AOMS103"

                     FWMsgRun(,{ || MSExecAuto({|x,y| Fina050(x,y)},_aAutoSE2,3)},"Aguarde...", "Criando título de nota de débito...") //Inclusao

                      If lMsErroAuto
                         //Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Erro ao gravar título de nota de débito, ocorrência não será salva.' , 1, 0 )
                         U_ITMsg('Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Erro ao gravar título de nota de débito, ocorrência não será salva. Print essa e a proxima tela.','Atenção!',_cAOMS074Vld,,,,.T.)  //HELP PARA O MVC
                         MostraErro()
                         _lRet := .F.
                         cfilant := _cfilold
                         nModulo := _nModAux
                         cModulo := _cModAux
                         Break
                      Else
                         //Posiciona no registro gravado no banco para comparar
                         ZF5->(DBSetOrder(4))
                         If ZF5->(DBSeek(_cfilold+_cNotaFiscal+_cserie+_oModelGrid:GetValue('ZF5_CODIGO',_nI)))
                            ZF5->(RecLock("ZF5",.F.))
                            ZF5->ZF5_CHVNDT:=(SE2->E2_FILIAL+SE2->E2_PREFIXO+SE2->E2_NUM+SE2->E2_PARCELA)
                            ZF5->(MSUnLock())
                           _oModelGrid:LoadValue('ZF5_CHVNDT',ZF5->ZF5_CHVNDT)
                         EndIf
                         //CRIA E APRESENTA PDF DE NOTA DE DÉBITO E ENVIA EMAIL
                         U_ROMS055()
                      EndIf

                      cfilant := _cfilold
                      nModulo := _nModAux
                      cModulo := _cModAux
                   EndIf
               EndIf
             EndIf
         EndIf

      Next  _nI  ///ACABA AQUI - For _nI := 1 To _oModelGrid:Length()

   EndIf
   cfilant := _cfilold

   If _lRet .And. (_nOperation == MODEL_OPERATION_DELETE .Or. _nOperation == MODEL_OPERATION_UPDATE)

      _cNotaFiscal := _oModelMaster:GetValue("ZF5_DOCOC")
      _cSerie      := _oModelMaster:GetValue("ZF5_SEROC")
      _cfilial     := xFilial("ZF5")//ZF5->ZF5_FILIAL
      _cdococ      := _cNotaFiscal//ZF5->ZF5_DOCOC
      ZF5->(DBSetOrder(4))

      For _nI := 1 To _oModelGrid:Length() //For 2

         _oModelGrid:GoLine(_nI)
         _cEstonado:= _oModelGrid:GetValue("ZF5_ESTONO")
         If _cEstonado = "S" .Or. _oModelGrid:IsDeleted() //SE ESTORNADO OU DELETADO NÃO LE
            Loop
         EndIf

         If !ZF5->(DBSeek(_cfilial+_cdococ+_cserie+_oModelGrid:GetValue('ZF5_CODIGO'))) // Se não achar não valida, pois é linha nova
            Loop
         EndIf
         _dencerrra   := ZF5->ZF5_DTFIN
         _cStatusOcorr:= ZF5->ZF5_STATUS
         _cCodigo     := AllTrim(Str(Val(_oModelGrid:GetValue('ZF5_CODIGO'))))  // Código da ocorrência por nota
         _csit := ""
         _lValidaLinha := .F.

         If _nOperation == MODEL_OPERATION_DELETE
            _lValidaLinha := .T.
         ElseIf _oModelGrid:IsDeleted()
            _lValidaLinha := .T.
         ElseIf _oModelGrid:IsUpdated() .And. U_AOMS003R(_oModel)
            _lValidaLinha := .T.
         EndIf

         //Valida se está excluindo linha com ocorrência encerrada
         If _lValidalinha .And. _nOperation == MODEL_OPERATION_DELETE .And. Posicione("ZFD",1,xFilial("ZFD")+ _cStatusOcorr,"ZFD_STATUS") == "E"
            _lRet := .F.
            Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Para excluir ocorrências primeiro reabra o status de todas as linhas!' , 1, 0 )
            Break
         EndIf

         _cPeriodo := ""
           If _lValidaLinha
            If DAY(_dencerrra) <= 25
               _cPeriodo := StrZero(MONTH( _dencerrra),2) + "/" + StrZero(YEAR(_dencerrra),4)
               _csit := Posicione("ZFZ",2,ZF5->ZF5_FILIAL + StrZero(MONTH(_dencerrra),2) + "/" + StrZero(YEAR(_dencerrra),4),"ZFZ_STATUS")

            Else

               If MONTH(_dencerrra) < 12
                  _cPeriodo := StrZero(MONTH( _dencerrra) + 1 ,2) + "/" + StrZero(YEAR(_dencerrra),4)
                  _csit := Posicione("ZFZ",2,ZF5->ZF5_FILIAL + StrZero(MONTH(_dencerrra)+1,2) + "/" + StrZero(YEAR(_dencerrra),4),"ZFZ_STATUS")

               Else
                  _cPeriodo :=  "01/" + StrZero(YEAR(_dencerrra)+1,4)
                  _csit := Posicione("ZFZ",2,ZF5->ZF5_FILIAL + "01/" + StrZero(YEAR(_dencerrra)+1,4),"ZFZ_STATUS")

               EndIf

            EndIf

         EndIf

         If _csit == '2' .And. _lRet
            _lRet := .F.
            Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Não é permitido alterar ocorrência encerrada em período ('+ _cPeriodo + ') já encerrado!' , 1, 0 )
            Break
         EndIf

         If _csit == '1' .And. _lRet .And. !(U_ITVACESS( 'ZZL' , 3 , 'ZZL_OCFRT' , 'C' ))
            _lRet := .F.
            Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Não é permitido alterar ocorrência encerrada em período (' + _cPeriodo + ') com encerramento logístico!' , 1, 0 )
            Break
         EndIf

         // Não Alterar/Excluir o Tipo de Ocorrência quando a integração For do RDC.
         If ! Empty(_oModelGrid:GetValue('ZF5_CODRDC'))

            _lTemPermicao:=U_ITACSUSR('ZZL_EXOCRD','S')

            If (_nOperation == MODEL_OPERATION_DELETE .Or. _oModelGrid:IsDeleted()) .And. !_lTemPermicao
               _lRet := .F.
               Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Usuário sem acesso para excluir ocorrências vindas/integradas do sistema RDC!' , 1, 0 )
               Break
            EndIf

            If _oModelGrid:IsUpdated() // _nOperation == MODEL_OPERATION_UPDATE .Or.
               If AllTrim(ZF5->ZF5_TIPOO) <> AllTrim(_oModelGrid:GetValue('ZF5_TIPOO'))
                  _lRet := .F.
                  Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Não é permitido alterar o campo "tipo de ocorrência", das ocorrências vindas/integradas do sistema RDC!' , 1, 0 )
                  Break
               EndIf
            EndIf
         EndIf

      Next _nI

   EndIf

   ZF5->(FWRestArea(_aarea))

   For _nI := 1 To _oModelGrid:Length()

       _oModelGrid:GoLine(_nI)
       _cEstonado    := _oModelGrid:GetValue("ZF5_ESTONO")
       If _cEstonado = "S" .Or. _oModelGrid:IsDeleted() //SE ESTORNADO OU DELETADO NÃO LE PARA VALIDAR
          Loop
       EndIf

       _cTipoOcorr   := _oModelGrid:GetValue('ZF5_TIPOO')
       _cTipoCusto   := _oModelGrid:GetValue('ZF5_TIPOC')   // Tipo de custo.
       _nCustoIt     := _oModelGrid:GetValue('ZF5_CUSTOI')  // Custo Italac
       _nCustoCli    := _oModelGrid:GetValue('ZF5_CUSTOC')  // Custo cliente
       _nCustoRepr   := _oModelGrid:GetValue('ZF5_CUSTOR')  // Custo Representante
       _nCustoTransp := _oModelGrid:GetValue('ZF5_CUSTOT')  // Custo Transportador
       _nCustoTerc   := _oModelGrid:GetValue('ZF5_CUSTER')  // Custo Terceiro
       _cGerDevol    := _oModelGrid:GetValue('ZF5_DEVOL')   // Gera Devolução S/N
       _cServOcorr   := _oModelGrid:GetValue('ZF5_SERVIC')  // Serviço Ocorrência - 1=Descarga;2=Deslocamento;3=Diaria;4=Reentrega;5=outros
       _cNfDev       := _oModelGrid:GetValue('ZF5_DOCDEV')  // Nota Fiscal de devolução
       _cSerDev      := _oModelGrid:GetValue('ZF5_SERDEV')  // Serie da Nota Fiscal de Devolução
       _nvaltransp   := _oModelGrid:GetValue('ZF5_CUSTOT')    //Custo transportador transportador
       _cndebit      := _oModelGrid:GetValue('ZF5_NDEBIT')   // Nota de debito
       _ctipocus     := _oModelGrid:GetValue('ZF5_TIPOC')   // Tipo de custo
       _cStatus      := _oModelGrid:GetValue('ZF5_STATUS')   // Status da ocorrência
       _cCodigo      := AllTrim(Str(Val(_oModelGrid:GetValue('ZF5_CODIGO'))))  // Código da ocorrência por nota
       _cpeddev      := _oModelGrid:GetValue('ZF5_PEDDEV')

       ZFC->(DBSetOrder(1))
       ZFC->(DBSeek(xFilial("ZFC")+_cTipoOcorr))

       If !Empty(ZFC->ZFC_CUSTO) .And. ZFC->ZFC_CUSTO <>  _cTipoCusto
          _lRet := .F.
          Help( ,, "Atenção",, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + " - O tipo de custo informado ("+_cTipoCusto+"), difere do tipo de custo do tipo de ocorrência: ("+ZFC->ZFC_CUSTO+")", 1, 0 )
          Exit
       ElseIf _cTipoCusto == "I" // Italac
          If Empty(_nCustoIt)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + " - O campo custo italac deve ser preenchido.", 1, 0 )
             Exit
          ElseIf ! Empty(_nCustoRepr) .Or. ! Empty(_nCustoCli) .Or. ! Empty(_nCustoTerc)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + " - Por ter selecionado o tipo de custo Italac, você deve preencher apenas o campo de valor de custo Italac.", 1, 0 )
             Exit
          EndIf
       ElseIf _cTipoCusto == "T" // Transportador
          If Empty(_nCustoTransp)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + " - O campo custo transportador deve ser preenchido.", 1, 0 )
             Exit
          EndIf
       ElseIf _cTipoCusto $ "RV" // Representante Externo / Vendedor Interno
          If Empty(_nCustoRepr)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + " - O campo custo representante deve ser preenchido.", 1, 0 )
             Exit
          ElseIf ! Empty(_nCustoCli) .Or. ! Empty(_nCustoTerc) .Or. !Empty(_nCustoIt)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + " - Por ter selecionado o tipo de custo Representante, você deve preencher apenas o campo de valor de custo Representante.", 1, 0 )
             Exit
          EndIf
       ElseIf _cTipoCusto == "C" // Cliente
          If Empty(_nCustoCli)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + " - O campo custo cliente precisa ser preenchido.", 1, 0 )
             Exit
          ElseIf ! Empty(_nCustoRepr) .Or. ! Empty(_nCustoTerc) .Or. !Empty(_nCustoIt)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + " - Por ter selecionado o tipo de custo Cliente, você deve preencher apenas o campo de valor de custo Cliente.", 1, 0 )
             Exit
          EndIf

       ElseIf _cTipoCusto == "3" // Terceiros
          If Empty(_nCustoTerc)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + " - O campo custo de Terceiros precisa ser preenchido.", 1, 0 )
             Exit
          ElseIf ! Empty(_nCustoRepr) .Or. !Empty(_nCustoIt) .Or. ! Empty(_nCustoCli)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + " - Por ter selecionado o tipo de custo Terceiro, você deve preencher apenas o campo de valor de custo Terceiro.", 1, 0 )
             Exit
          EndIf
       EndIf

       If _cGerDevol == "S"
          If Empty(_cNfDev) .Or. Empty(_cSerDev)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + " - O numero e série da nota fiscal de devolução devem ser preenchidos, pois o tipo de custo informado gera devolução.", 1, 0 )
             Exit
          EndIf
       EndIf

       If !Empty(ZFC->ZFC_SERVI) .And. _cServOcorr <> ZFC->ZFC_SERVI
          _lRet := .F.
          Help( ,, "Atenção",, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + " - O tipo de serviço informado ( "+_cServOcorr+" ) difere de tipo de serviço do tipo de ocorrência: ( "+ZFC->ZFC_SERVI+" )", 1, 0 )
          Exit
       EndIf

       //Se está validado e é exclusão ou alteração de encerrado para outro status
       // e tem nota de débito, tenta deletar o título vinculado
       If _lRet .And. ( _nOperation == MODEL_OPERATION_DELETE .OR.;
          (_nOperation == MODEL_OPERATION_UPDATE .And.  ( _oModelGrid:IsDeleted()  .Or.   _oModelGrid:IsUpdated() )) )

          ZF5->(DBSetOrder(4))
          If ZF5->(DBSeek(_cfilial+_cdococ+_cserie+_oModelGrid:GetValue('ZF5_CODIGO')))

            //Exclui pedido de descarte se existir
            If Posicione("ZFD",1,xFilial("ZFD")+_cStatus,"ZFD_STATUS") != "E" .And. Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_STATUS") == "E"
               SC5->(DBSetOrder(1))
               If SC5->(DBSeek(xFilial("SC5")+_cpeddev))
                  If U_ITMsg("Existe pedido de descarte para essa ocorrência. Pedido será excluido com a reabertura da ocorrência. Deseja continuar?",;
                                     "Atenção","Pedido: "+xFilial("SC5")+" "+_cpeddev+' - Ocorrência: ' + StrZero(Val(_cCodigo),6),2,2,2)
                     //Tenta fazer exclusão do pedido de descarte
                     _lRet := AOMS003DP()
                     If !_lRet
                        Break
                     EndIf
                  Else
                     Help( ,, 'Atenção',, 'Processo cancelado' , 1, 0 )
                     _lRet := .F.
                     Break
                  EndIf
               Else
                  _oModelGrid:LoadValue('ZF5_PEDDEV','')
                  _cpeddev := ''
               EndIf
            EndIf
            //         EXCLUI TITULO DE DÉBITO SE EXISTIR
            If Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_STATUS") == "E" .And. Posicione("ZFD",1,xFilial("ZFD")+_cStatus,"ZFD_STATUS") != "E"
               If ZF5->ZF5_NDEBIT == "S"
                  _cfilold := cfilant
                  //Se For nota de faturamento de um troca nota muda para a filial de carregamento para incluir a nota de débito
                  SF2->(DBSetOrder(1))
                  If SF2->(DBSeek(xFilial("SF2")+_cNotaFiscal+_cSerie))
                     SC5->(DBSetOrder(1))
                     If SC5->(DBSeek(xFilial("SC5")+SF2->F2_I_PEDID))
                         If SC5->C5_I_TRCNF = "S" .And. SC5->C5_I_FLFNC != SC5->C5_FILIAL
                             cfilant := SC5->C5_I_FLFNC
                         EndIf
                     EndIf
                  EndIf
                  _cFornece:=""
                  _cLoja:=""
                  If ZF5->ZF5_TIPOC == "T"
                     _cFornece := AllTrim(ZF5->ZF5_TRANSP)
                     _cLoja    := ZF5->ZF5_LJTRAN
                  ElseIf ZF5->ZF5_TIPOC == "3"
                     _cFornece := ZF5->ZF5_FORTER
                     _cLoja    := ZF5->ZF5_LOJTER
                  EndIf

                  If !Empty(ZF5->ZF5_CHVNDT)
                     If Len(AllTrim(ZF5->ZF5_CHVNDT)) = Len(SE2->E2_FILIAL+SE2->E2_PREFIXO+SE2->E2_NUM)//CHAVE SEM PARCELA
                        _cSeekSE2:=ZF5->ZF5_CHVNDT + "01" + "NDF"+_cFornece+_cLoja//A chave e o cfilant já estam com a filai certa
                     Else//CHAVE COM PARCELA - NOVO
                        _cSeekSE2:=ZF5->ZF5_CHVNDT + "NDF"+_cFornece+_cLoja//A chave e o cfilant já estam com a filai certa
                     EndIf
                  Else
                     _cSeekSE2:=xFilial("SE2")+"NDT"+SubStr(_cNotaFiscal,2,8) + _cCodigo + "01" + "NDF"//o cfilant já tá na filial certa
                  EndIf
                  SE2->(DBSetOrder(1))
                  If SE2->(DBSeek(_cSeekSE2))
                     //              EXCLUI TÍTULO DE DÉBITO 
                     _lerro := !(AOMS003DT( ZF5->(RECNO()),_oModelGrid ))
                     If _lerro
                        // JÁ DÁ MENSAGEM DE ERRO DENTRO DA FUNÇÃO AOMS003DT ()
                        //Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Erro ao excluir título de nota de débito, ocorrência não será salva/apagada.' , 1, 0 )
                        _lRet := .F.
                        cfilant := _cfilold
                        Break
                     EndIf
                  EndIf
               EndIf
               cfilant := _cfilold
            EndIf

          EndIf
       EndIf
   Next _nI

   cfilant := _cfilold

   If _lRet  .And. (_nOperation == MODEL_OPERATION_INSERT .Or. _nOperation == MODEL_OPERATION_UPDATE)

      ZF5->(DBSetOrder(4))
      _cNotaFiscal := _oModelMaster:GetValue("ZF5_DOCOC")
      _cSerie      := _oModelMaster:GetValue("ZF5_SEROC")
      For _nI := 1 To _oModelGrid:Length()

         _oModelGrid:GoLine(_nI)
         _cEstonado:= _oModelGrid:GetValue("ZF5_ESTONO",_nI)
         If _cEstonado = "S" .Or. _oModelGrid:IsDeleted() //SE ESTORNADO OU DELETADO NÃO LE
            Loop
         EndIf
         _cCodigo  := _oModelGrid:GetValue('ZF5_CODIGO',_nI)  // Código da ocorrência por nota
         _cStatus  := _oModelGrid:GetValue('ZF5_STATUS',_nI)  // Status da ocorrência
         _cTipoO   := _oModelGrid:GetValue('ZF5_TIPOO' ,_nI)  // Tipo de ocorrência

         //Posiciona no registro gravado no banco para comparar
         lAchou:=ZF5->(DBSeek(xFilial("ZF5")+_cNotaFiscal+_cserie+_cCodigo))
         lEncerrou:= Posicione("ZFD",1,xFilial("ZFD")+_cStatus,"ZFD_STATUS") == "E" .AND.;
                     (!lAchou .Or. Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_STATUS") != "E")//PARA NÃO ENVIAR DE NOVO O ="E" GRAVADO

         //SE STATUS ESTÁ ENCERRANDO, ENVIA E-MAIL DE COBRANÇA
         If lEncerrou .And. !_lEnviou
            //SE GRAVAÇÃO É VÁLIDA SOLICITA ENVIO DE EMAIL DE COBRANÇA
            //SE For DEVOLUÇÃO.
            _cEnvCob := Posicione("ZFC",1,xFilial("ZFC")+_cTipoO,"ZFC_ENVCOB")
            If _cEnvCob == "S" .And. U_ITMsg("Envia cancelamento de cobrança para nota " + _cNotaFiscal + " com ocorrência de devolução?","Atenção",'Cancelamento do Ocorrência ' + StrZero(Val(_cCodigo),6),2,2,2)
               _cMotivo:= _oModelGrid:GetValue('ZF5_MOTIVO',_nI)  // Motivo da ocorrência
                _cMotcus:= _oModelGrid:GetValue('ZF5_MOTCUS',_nI)  // Motivo do Custo
               //ENVIA WF DE CANCELAMENTO DE COBRANÇA
               U_AOMS003J(_cNotaFiscal,_cserie, .T.,.F. ,_cTipoO + "-" + AllTrim(_cMotivo),_cMotcus)
            EndIf
         EndIf

          _lPendente:= !lAchou .And. (_cStatus == '000006'.AND. Posicione("ZFC",1,xFilial("ZFC")+_cTipoO,"ZFC_ENVREP") = "S")

          If _lPendente//ENVIA WF AO COMERCIAL
             
             _lEmail := .T.
             _aOcorreIt:= {}
             aAdd(_aOcorreIt,_oModelGrid:GetValue("ZF5_DTOCOR"))//01
             aAdd(_aOcorreIt,_oModelGrid:GetValue("ZF5_CODIGO"))//02
             aAdd(_aOcorreIt,_oModelGrid:GetValue("ZF5_MOTIVO"))//03
             aAdd(_aOcorreIt,_oModelGrid:GetValue("ZF5_MOTCUS"))//04
             aAdd(_aOcorreIt,_oModelGrid:GetValue("ZF5_TIPOO "))//05
             aAdd(_aOcorreIt,_oModelGrid:GetValue("ZF5_TRANSP"))//06
             aAdd(_aOcorreIt,_oModelGrid:GetValue("ZF5_LJTRAN"))//07
             aAdd(_aOcorreIt,_oModelGrid:GetValue("ZF5_NTRANS"))//08
             aAdd(_aDadosEmailCom,_aOcorreIt)
          EndIf
      Next _nI
   EndIf

   ZF5->(FWRestArea(_aarea))

 End Sequence

 cfilant := _cFilSalva

 If !_lRet
     disarmtransaction()
    _lEmail := .F.
    _oModelGrid:GoLine(_nSlvaLin)
 EndIf

 End Transaction

 RestOrd(_aOrd)
 FwRestArea(_aAreaM0)

Return _lRet

/*
===============================================================================================================================
Programa--------: AOMS003S
Autor-----------: Julio de Paula Paz
Data da Criacao-: 09/08/2016
Descrição-------: Rotina de exibição e seleção de dados para aprovação ou rejeição.
Parametros------: _cOpcao = Opção selecionada pelo usuário = "REJEITAR" ou "APROVAR"
Retorno   ------: Nenhum
===============================================================================================================================
*/
User Function AOMS003S(_cOpcao)

 Local _lInverte := .F.
 Local _lRet := .F.
 Local _aSizeAut  := MsAdvSize(.T.)
 Local _bOk, _bCancel , _cTitulo
 Local _aCores
 Local _nLin1,_nCol1, _nLin2, _nCol2
 Local _aStructZF5
 Local _aOrd := SaveOrd({"ZF5"})
 Local _cMsg, _nI
 Local _oTemp

 Private _aCampos := {}
 Private _oMarkApr, _oDlgApr
 Private _cMarcaApr  := GetMark()
 Private _lMontaTela := .T.
 Private _cCodAprovar  := SuperGetMV('IT_APROVAR',.T.,'')
 Private _cCodRejeitar := SuperGetMV('IT_REJEITA',.T.,'')
 Private aHeader := {}

 Begin Sequence
   aHeader := {}
   FillGetDados(1,"ZF5",1,,,{||.T.},,,,,,.T.)
   nUsado := Len(aHeader)

   // Define as cores dos itens de legenda.
   _aCores := {}
   aAdd(_aCores,{'Posicione("ZFD",1,xFilial("ZFD")+TRBZF5->ZF5_STATUS,"ZFD_STATUS")=="P"',"BR_VERDE"	})    // Pendente
   aAdd(_aCores,{'Posicione("ZFD",1,xFilial("ZFD")+TRBZF5->ZF5_STATUS,"ZFD_STATUS")=="E"',"BR_VERMELHO"	})    // Efetivado
   aAdd(_aCores,{'Posicione("ZFD",1,xFilial("ZFD")+TRBZF5->ZF5_STATUS,"ZFD_STATUS")=="N"',"BR_CINZA"	})    // Não Procede
   aAdd(_aCores,{'Posicione("ZFD",1,xFilial("ZFD")+TRBZF5->ZF5_STATUS,"ZFD_STATUS")=="T"',"BR_AMARELO"	})    // Em tratamento

   If _cOpcao == "REJEITAR"
      _cTitulo := "Gestão de Ocorrências de Frete - Rejeição de Ocorrências"
   Else // "APROVAR"
      _cTitulo := "Gestão de Ocorrências de Frete - Aprovação de Ocorrências"
   EndIf

   // Cria tabela temporária.
   _aStructZF5 := ZF5->(DbStruct())
   _nI := aScan(_aStructZF5,{|x| x[1]="ZF5_STATC"})
   _aStructZF5[_nI,3] := 25 // Altera o tamanho do campo "ZF5_STATC" para 25 posições.

   _nI := aScan(_aStructZF5,{|x| x[1]="ZF5_STATUS"})
   _aStructZF5[_nI,3] := 25 // Altera o tamanho do campo "ZF5_STATUS" para 25 posições.

   aAdd(_aStructZF5,{"WK_OK"   ,"C",2	,0 })
   aAdd(_aStructZF5,{"WKRECNO" ,"N",10  ,0 })

   // Abre o arquivo TRBZF5 criado dentro do banco de dados protheus.
   _oTemp := FWTemporaryTable():New( "TRBZF5",  _aStructZF5 )

   // Cria os indices para o arquivo.
   _oTemp:AddIndex( "01", {"ZF5_DOCOC","ZF5_SEROC"} )
   _oTemp:Create()

   // Carrega dados na tabela temporária.
   Processa( {||U_AOMS003D(  ) } , 'Aguarde!' , 'Filtrando dados...' )

   // Monta colunas do MsSelect
                    //Campo         , "" , Titulo                          , Picture
   aAdd( _aCampos , { "WK_OK"		,    , "Marca"                         ,"@!"})
   aAdd( _aCampos , { "ZF5_CODIGO"  , "" , "Codigo Ocorr"                  ,"@!"})

   For _nI := 1 To Len(aHeader)
       If X3Uso(aHeader[_nI,7]) .And. AllTrim(aHeader[_nI,2]) <> "ZF5_CODIGO"
          aAdd( _aCampos , { aHeader[_nI,2]		, "" , AllTrim(aHeader[_nI,1]) , aHeader[_nI,3]})
       EndIf
   Next _nI

   _bOk := {|| If(U_AOMS003L(_cOpcao),(_lRet := .T., _oDlgApr:End()),)}
   _bCancel := {|| _lRet := .F., _oDlgApr:End()}

   TRBZF5->(DBGoTop())

   // Monta a tela de dados com MSSELECT.
   _nLin1 := 9
   _nCol1 := 0
   _nLin2 := _aSizeAut[6] * 0.079023  // 55
   _nCol2 := _aSizeAut[5] * 0.126138  // 194

   _aButtons:={}
   aAdd(_aButtons,{"",{|| U_AOMS003F("T") },"Marc/Des","Marca/Desmarca Todos"})
   aAdd(_aButtons,{"",{|| U_AOMS003G()    },"Legenda" ,"Legenda"})

   Define MsDialog _oDlgApr Title _cTitulo From _nLin1,_nCol1 To _nLin2,_nCol2 Of oMainWnd

      _oMarkApr := MsSelect():New("TRBZF5","WK_OK","",_aCampos,@_lInverte, @_cMarcaApr,{_aSizeAut[7]+20, 5, _aSizeAut[4], _aSizeAut[3]}) //,,,,,_aCores)
      _oMarkApr:bAval := {|| U_AOMS003F("P")}
      _lMontaTela := .F.
      _oDlgApr:lMaximized:=.T.

   Activate MsDialog _oDlgApr On Init (EnchoiceBar(_oDlgApr,_bOk,_bCancel,,_aButtons), _oMarkApr:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT , _oMarkApr:oBrowse:Refresh() )

   If _lRet
      If _cOpcao == "REJEITAR"
         _cMsg := "Confirma a rejeição da(s) ocorrência(s) de frete selecionada(s) e a alteração de seu Status?"
      Else  // "APROVAR"
         _cMsg := "Confirma a aprovação da(s) ocorrência(s) de frete selecionada(s) e a alteração de seu Status?"
      EndIf

      If !U_ITMsg(_cMsg,'Atenção!',,2,2,2)
         Break
      EndIf

      If _cOpcao == "APROVAR"
         If Empty(_cCodAprovar)
            U_ITMsg("Código de 'Status' da aprovação da ocorrência não preenchido no parâmetro IT_APROVAR. Não é possível aprovar a ocorrência.","Atenção",,1)
            Break
         EndIf

         ZFD->(DBSetOrder(1)) // ZFD_FILIAL+ZFD_CODIGO
         If ! ZFD->(DBSeek(xFilial("ZFD")+_cCodAprovar))
            U_ITMsg("Código de 'Status' da aprovação da ocorrência não cadastrado no cadastro de Status de Ocorrências. Não é possível aprovar a ocorrência.","Atenção",,1)
            Break
         EndIf
      Else
         If Empty(_cCodRejeitar)
            U_ITMsg("Código de 'Status' de rejeição da ocorrência não preenchido no parâmetro IT_REJEITAR. Não é possível rejeitar a ocorrência.","Atenção",,1)
            Break
         EndIf

         ZFD->(DBSetOrder(1)) // ZFD_FILIAL+ZFD_CODIGO
         If ! ZFD->(DBSeek(xFilial("ZFD")+_cCodRejeitar))
            U_ITMsg("Código de 'Status' da rejeição da ocorrência não cadastrado no cadastro de Status de Ocorrências. Não é possível rejeitar a ocorrência.","Atenção",,1)
            Break
         EndIf
      EndIf

      _lAtualizou := .F.

      TRBZF5->(DBGoTop())
      While ! TRBZF5->(Eof())
         If ! Empty(TRBZF5->WK_OK)
            ZF5->(DBGoTo(TRBZF5->WKRECNO))
            If _cOpcao == "REJEITAR"
               ZF5->(RecLock("ZF5",.F.))
               ZF5->ZF5_STATUS := _cCodRejeitar
               ZF5->ZF5_APRREJ := "R" // Rejeitado
               ZF5->ZF5_USRAPR := SubStr(cUsuario, 7,15)
               ZF5->ZF5_DTAPRR := Date()
               ZF5->ZF5_HRAPRR := SubStr(Time(),1,5)
               ZF5->(MSUnLock())
               _lAtualizou := .T.
            Else  // "APROVAR"
               _lAtualizou := .T.
               ZF5->(RecLock("ZF5",.F.))
               ZF5->ZF5_STATUS := _cCodAprovar
               ZF5->ZF5_APRREJ := "A" // Aprovado
               ZF5->ZF5_USRAPR := SubStr(cUsuario, 7,15)
               ZF5->ZF5_DTAPRR := Date()
               ZF5->ZF5_HRAPRR := SubStr(Time(),1,5)
               ZF5->(MSUnLock())
            EndIf
         EndIf

         TRBZF5->(DBSkip())
      EndDo

      If _cOpcao == "APROVAR"
         If _lAtualizou
            U_ITMsg("Aprovação realizada com sucesso.","Atenção",,1)
         Else
            U_ITMsg("Não foi possível realizar a aprovação.","Atenção",,1)
         EndIf
      Else
         If _lAtualizou
            U_ITMsg("Rejeição realizada com sucesso.","Atenção",,1)
         Else
            U_ITMsg("Não foi possível realizar a rejeição.","Atenção",,1)
         EndIf
      EndIf
   EndIf

 End Sequence

 TRBZF5->(DBCloseArea())

 RestOrd(_aOrd)

Return

/*
===============================================================================================================================
Programa--------: AOMS003D
Autor-----------: Julio de Paula Paz
Data da Criacao-: 17/08/2016
Descrição-------: Carrega os dados das ocorrências de frete filtrados do Comercial, para seleção e aprovação ou rejeição.
Parametros------: Nenhum
Retorno   ------: Nenhum
===============================================================================================================================
*/
User Function AOMS003D()

 Local _cQry, _nTotreg
 Local _nRegAtu := ZF5->(Recno())
 Local _nI, _nJ
 Local _aStatusC := {}
 Local cAlias:=GetNextAlias()

 Begin Sequence

    _aStatusC := {{"P","PENDENTE"},{"T","TRATAMENTO"},{"E","ENCERRADO"},{"S","SEM CUSTO"} }

    _cQry := " SELECT ZF5.R_E_C_N_O_ AS NRRECNO FROM "+RetSqlName("ZF5")+" ZF5 "
    _cQry += " WHERE ZF5.D_E_L_E_T_ = ' ' AND ZF5_FILIAL = '"+xFilial("ZF5")+"' "

    MPSysOpenQuery( _cQry , cAlias )

    DBSelectArea(cAlias)
    COUNT TO _nTotreg

    If _nTotreg = 0
       U_ITMsg("Não existem ocorrências de frete a serem exibidas.","Atenção",,1)
       Break
    EndIf

    ProcRegua(_nTotreg)

    (cAlias)->(DBGoTop())
    While ! (cAlias)->(Eof())
       IncProc("Filtrando dados de Ocorrências de Frete...")

       ZF5->(DBGoTo((cAlias)->NRRECNO))

       TRBZF5->(DbAppend())
       For _nI := 1 To TRBZF5->(FCount())
           If AllTrim(TRBZF5->(FieldName(_nI))) $ "WK_OK/WKRECNO"
              Loop
           EndIf
           &("TRBZF5->"+TRBZF5->(FieldName(_nI))) :=  &("ZF5->"+TRBZF5->(FieldName(_nI)))
       Next _nI

       TRBZF5->ZF5_STATUS := Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_DESCRI")
       _nJ := aScan(_aStatusC,{|x| x[1]=ZF5->ZF5_STATC})
       TRBZF5->ZF5_STATC :=  If(_nJ > 0,_aStatusC[_nJ,2],"")
       TRBZF5->WKRECNO := (cAlias)->NRRECNO

       (cAlias)->(DBSkip())
    EndDo
    TRBZF5->(DBGoTop())

 End Sequence

 (cAlias)->(DBCloseArea())

 ZF5->(DBGoTo(_nRegAtu))

Return

/*
===============================================================================================================================
Programa--------: AOMS003L
Autor-----------: Julio de Paula Paz
Data da Criacao-: 17/08/2016
Descrição-------: Verifica se existe registros marcados na tela de ocorrências de frete filtrados do Comercial,
                  para seleção e aprovação ou rejeição.
Parametros------: _cOpcao = Opção selecionada pelo usuário = "REJEITAR" ou "APROVAR"
Retorno   ------: Nenhum
===============================================================================================================================
*/
User Function AOMS003L(_cOpcao)

   Local _lRet := .F.
   Local _cMsg, _lTemMarca
   Local _nRegAtu := TRBZF5->(Recno())

   If _cOpcao == "REJEITAR"
      _cMsg := "Não existem dados marcados para rejeição."
   Else  // "APROVAR"
      _cMsg := "Não existem dados marcados para aprovação."
   EndIf

   _lTemMarca := .F.

   TRBZF5->(DBGoTop())
   While ! TRBZF5->(Eof())
      If ! Empty(TRBZF5->WK_OK)
         _lTemMarca := .T.
         _lRet := .T.
         Exit
      EndIf

      TRBZF5->(DBSkip())
   EndDo

   If ! _lTemMarca
      U_ITMsg(_cMsg,"Atenção",,1)
   EndIf

   TRBZF5->(DBGoTo(_nRegAtu))

Return _lRet

/*
===============================================================================================================================
Programa--------: AOMS003F
Autor-----------: Julio de Paula Paz
Data da Criacao-: 17/08/2016
Descrição-------: Função para marcar e desmarcar todas as notas fiscais da carga.
Parametros------: _cTipoMarca = "T" = Marca e desmarca todos os registros.
                  _cTipoMarca = "P" = Marca e desmarca apena o registro posisionado.
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS003F(_cTipoMarca)

    Local _cSimboloMarca := Space(2)
    Local _nRegAtu := TRBZF5->(Recno())

    If Empty(TRBZF5->WK_OK )
       _cSimboloMarca := _cMarcaApr
    Else
       _cSimboloMarca := Space(2)
    EndIf

    If _cTipoMarca == "P"
       TRBZF5->WK_OK := _cSimboloMarca
    Else
       TRBZF5->(DBGoTop())
       While ! TRBZF5->(Eof())
          TRBZF5->WK_OK := _cSimboloMarca
          TRBZF5->(DBSkip())
       EndDo

    EndIf

    TRBZF5->(DBGoTo(_nRegAtu))
    _oMarkApr:oBrowse:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AOMS003G
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/06/2016
Descrição---------: Legenda da rotina de aprovação ou rejeição de ocorrências.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS003G()

   Local _aLegenda := {}

   aAdd(_aLegenda,{"BR_VERDE"    ,"Pendente"})
   aAdd(_aLegenda,{"BR_VERMELHO" ,"Efetivado"})
   aAdd(_aLegenda,{"BR_CINZA"    ,"Não Procede"})
   aAdd(_aLegenda,{"BR_AMARELO"  ,"Em tratamento"})

   BrwLegenda("Gestão de Ocorrências de Frete", "Legenda", _aLegenda)

Return
/*
===============================================================================================================================
Programa----------: AOMS003P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/06/2016
Descrição---------: Bloco de Código de pré-validação do submodelo. O bloco é invocado na 
                    deleção de linha, no 
                    undelete da linha, na 
                    inserção de uma linha e nas tentativas de 
                    atribuição de valor.
Parametros--------: _oModelGrid = Modelo de Dados
                    _nLine      = Linha do grid
                    _cAction    = Ações: "UNDELETE" - "DELETE" - "ADDLINE" : nesse caso não será passado nada para o parametro de numero de linha
                                         "SETVALUE" : nesse caso, serão passados mais três parametros. (VALID)
                                         "CANSETVALUE" : nesse caso será passado mais um parametro.  (WHEN)
                                         "ISENABLE" 
                    _cField     =  identificador do campo que está sendo atualizado (SETVALUE e CANSETVALUE)
                    _cValue     =  valor que está sendo atribuído ao campo (SETVALUE)
                    _cOldValue  =  valor que estava atribuído ao campo antes da atualização (SETVALUE)
Retorno-----------: True (.T.) ou False(.F.)
===============================================================================================================================
*/
User Function AOMS003P(_oModelGrid, _nLine, _cAction, _cField, _cValue, _cOldValue)
 Local _cSituacao    As char
 Local _cUsersHab    As char
 Local _oModel       As Object
 Local _oModelMaster As Object
 Local _nOperation   As Numeric
 Local _lTemSaldo    As Logical
 Local _lAchou       As Logical
 Local lTemObjeto    As Logical
 Local _lRet         := .T.

 Begin Sequence

    If _cField == "LEGENDA" .And. _cAction == 'CANSETVALUE'
       _lRet:=.F.
       AOMS03Leg(.F.)
       BREAK //SAIR SEMPRE POIS É UM CAMPO ESPECIFICO
    EndIf

    _nOperation:= _oModelGrid:GetOperation()
    _cUsersHab := SuperGetMV("IT_USPROTI",.F.,"002355") 
    _lTemSaldo := .F.
    _lAchou    := .F.
    lTemObjeto := .F.

    If _cAction == 'CANSETVALUE' .And. (_cField = "ZF5_TIPOO" .Or. _cField = "ZF5_DTOCOR")//WHEN DOS CAMPOS
       If _nOperation == MODEL_OPERATION_UPDATE .And. !_oModelGrid:IsInserted()// ALTERANDO OCORENCIA JÁ GRAVADA
          _cTipoOcorr := _oModelGrid:GetValue("ZF5_TIPOO")
          _cDtTran    :=  Posicione("ZFC",1,xFilial("ZFC")+_cTipoOcorr,"ZFC_DTTRAN") // 1 = ZFC_FILIAL+ZFC_CODIGO
          If !Empty(_cTipoOcorr) .And. _cDtTran $ "A,B,C,D,E,F"
             If _oModelGrid:GetValue("ZF5_ESTONO") = "S"
                U_ITMsg( 'Não é permitido alterar Tipo/Data da ocorrências de frete estornadas.' ,'Atenção',;
                         "Aperte o DEL nessa ocorrência para cancelar o estorno caso necessaro alterar outros campos.",1,,,.F.)
             Else
                U_ITMsg( 'Não é permitido alterar Tipo/Data da ocorrências de frete com o tipo igual a '+_cDtTran ,'Atenção',;
                         "Aperte o DEL nessa ocorrência para estornar-lá, e insira uma nova ocorrencia com as alterações necessarias",1,,,.F.)
             EndIf
             _lRet := .F.
          EndIf
       EndIf
       If !_lRet
          BREAK
       EndIf
    EndIf
    
    If _cAction == 'SETVALUE' .And. _cField = "ZF5_STATUS" //ALTERANDO O STATUS PARA "00001-ENCERRADO"
       lEncerrou:= Posicione("ZFD",1,xFilial("ZFD")+_cValue   ,"ZFD_STATUS") == "E" .AND.; //Alterando Para STATUS "00001-ENCERRADO"
                  (Posicione("ZFD",1,xFilial("ZFD")+_cOldValue,"ZFD_STATUS") != "E")//UM STATUS diferente de encerrado
       _nOpcaoAtual:=MODEL_OPERATION_UPDATE
       If lEncerrou .And. (_nOperation == _nOpcaoAtual .Or. _oModelGrid:IsInserted())// ALTERANDO OCORENCIA JÁ GRAVADA OU INCLUINDO
          _nValtot:=_oModelGrid:GetValue('ZF5_CUSTOI')+;
                    _oModelGrid:GetValue('ZF5_CUSTOC')+;
                    _oModelGrid:GetValue('ZF5_CUSTOR')+;
                    _oModelGrid:GetValue('ZF5_CUSTOT')+;
                    _oModelGrid:GetValue('ZF5_CUSTO' ) 
          If _nValtot > 0 .And. Empty(_oModelGrid:GetValue("ZF5_CAUCUS") )
             Help( ,, 'Encerramento',,'Se tem Valor de custo o campo "Causador do Custo" deve ser informado.', 1, 0, .F. )
             _lRet := .F.
          EndIf
       EndIf
       If !_lRet
          BREAK
       EndIf
    EndIf

    _oModel:=FwModelActivete()
    If ValType(_oModel) = "O"
       _oModelMaster := _oModel:GetModel("ZF5MASTER")
       If ValType(_oModelMaster) = "O"
          lTemObjeto:=.T.
       EndIf
    EndIf
      
    //Chamado 50481 - Vanderlei / Jerry - fazer a tratativa para quando ocorrência tem NDT vinculada, não permitir alterar os dados da ZF5 a não ser informar o código 000001 que é estorno do encerramento.
    If _cAction == 'DELETE' .Or. (_cAction == 'CANSETVALUE' .And. _cField <> "ZF5_STATUS") //WHEN DE TODOS DOS CAMPOS
       If _nOperation == MODEL_OPERATION_UPDATE .And. !_oModelGrid:IsInserted()// ALTERANDO OCORENCIA JÁ GRAVADA
          If lTemObjeto
             _cDoc   := _oModelMaster:GetValue("ZF5_DOCOC")
             _cSerie := _oModelMaster:GetValue("ZF5_SEROC")
          EndIf
          ZF5->(DBSetOrder(4))
          If lTemObjeto .And. ZF5->(DBSeek(xFilial("ZF5")+_cDoc+_cSerie+_oModelGrid:GetValue('ZF5_CODIGO'))) .AND.;
             Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_STATUS") == "E"  //Para STATUS "00001-ENCERRADO"
             If ZF5->ZF5_NDEBIT == "S"
                U_ITMsg('Não é permitido alterar os campos ou deletar as ocorrências com nota de débito.' ,'Atenção',;                                      //,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes,_cMaisDetalhes,_lRetXNil
                           "Altere o Status para reabrir a ocorrencia , grave para estornar a nota de débito, e entre novamente nas ocorrencias para alterar.",1     ,       ,        ,.F.)
                _lRet := .F.
             ElseIf  ZF5->ZF5_GERDEV == "S"
                U_ITMsg('Não é permitido alterar os campos ou deletar as ocorrências com pedido de descarte.' ,'Atenção',;
                          "Altere o Status para reabrir a ocorrencia , grave para estornar pedido de descarte, e entre novamente nas ocorrencias para alterar.",1    ,       ,        ,.F.)
                _lRet := .F.
             EndIf
          EndIf
       EndIf
       If !_lRet
          BREAK
       EndIf
    EndIf

    If _cAction == 'DELETE' .And. _nOperation == MODEL_OPERATION_UPDATE
       _cSituacao := _oModelGrid:GetValue('ZF5_APRREJ')
       If ! Empty(_cSituacao)
          _lRet := .F.
          Help( ,, 'Atenção',, 'Não é permitido apagar ocorrências de frete rejeitadas ou aprovadas: '+_cSituacao , 1, 0 , .F. )
       EndIf
    EndIf

    If _lRet
       If lTemObjeto
          _cDoc   := _oModelMaster:GetValue("ZF5_DOCOC")
          _cSerie := _oModelMaster:GetValue("ZF5_SEROC")
       EndIf
       _cTipo     := "NF "
       _cCodigo   := _oModelGrid:GetValue("ZF5_CODIGO")
       
       If _cAction == 'DELETE' .And. _nOperation == MODEL_OPERATION_UPDATE

          _cFilial   := xFilial("ZM4")
          ZFC->(DBSetOrder(1))
          If ZFC->(DBSeek(xFilial("ZFC")+_oModelGrid:GetValue("ZF5_TIPOO")))
             If ZFC->ZFC_PROTIT == "S"
                If __cUserId $ _cUsersHab .And. _oModelGrid:GetValue("ZF5_DPRORR") > 0
                   ZM4->(DBSetOrder(1))
                   If lTemObjeto .And. ZM4->(DBSeek(_cFilial+_cDoc+_cSerie+_cTipo+_cCodigo))
                      If ZM4->ZM4_STATUS == "A"
                         _lRet := .F.
                         Help( ,, 'Atenção',, 'Não é permitido deletar ocorrências de frete com prorrogação de vencimento aprovada.' , 1, 0  )
                      EndIf
                   EndIf
                Else
                   _lRet := .F.
                   Help( ,, 'Atenção',, 'Usuário sem permissão para utilizar este tipo de ocorrencia.' , 1, 0 , .F.,,,,,{"Para habilitar a utilização solicite ao administrador do sistema."})
                EndIf
             EndIf
          EndIf

       ElseIf _cField == "ZF5_TIPOO" .And. _cAction == "SETVALUE" .And. ( _nOperation == MODEL_OPERATION_UPDATE .Or. _nOperation == MODEL_OPERATION_INSERT)

          //Se registro já gravado não deixa aterar ocorrencia qdo For Prorogação de Vencto
          If _nOperation == MODEL_OPERATION_UPDATE
             ZF5->(DBSetOrder(4)) // ZF5_FILIAL+ZF5_DOCOC+ZF5_SEROC+ZF5_CODIGO
             If lTemObjeto .And. ZF5->(DBSeek(xFilial("ZF5")+_cDoc+_cSerie+_cCodigo))
                If ZF5->ZF5_TIPOO <> M->ZF5_TIPOO
                   ZFC->(DBSetOrder(1))
                   If ZFC->(DBSeek(xFilial("ZFC")+ZF5->ZF5_TIPOO))
                      If ZFC->ZFC_PROTIT == "S"
                          _lRet := .F.
                          Help( ,, 'Atenção',, 'Não é permitido trocar este Tipo de ocorrência de frete.' , 1, 0, .F.,,,,,{"Delete a ocorrencia e inclua uma nova."})
                      EndIf
                   EndIf
                EndIf
             EndIf
          EndIf

          //Verifica se há saldo nos Titulos qdo For Prorogação de Vencto
          ZFC->(DBSetOrder(1))
          If ZFC->(DBSeek(xFilial("ZFC")+M->ZF5_TIPOO))
             If ZFC->ZFC_PROTIT == "S"
                If lTemObjeto .And. __cUserId $ _cUsersHab .And. _oModelGrid:GetValue("ZF5_DPRORR") > 0
                   _lTemSaldo := .F.
                   _lAchou := .F.
                   SE1->(DBSetOrder(1))
                   If SE1->(DBSeek(xFilial("SE1")+_cSerie+_cDoc+Space(Len(SE1->E1_PARCELA))+_cTipo))
                      _lAchou := .T.
                   ElseIf SE1->(DBSeek(xFilial("SE1")+_cSerie+_cDoc+StrZero(1,Len(SE1->E1_PARCELA))+_cTipo))
                      _lAchou := .T.
                   EndIf

                   If _lAchou
                      While SE1->(xFilial("SE1")+_cDoc+_cSerie+_cTipo == E1_FILIAL+E1_NUM+E1_PREFIXO+E1_TIPO) .And. SE1->(!Eof())
                         If SE1->E1_SALDO > 0
                            _lTemSaldo := .T.
                         EndIf
                         SE1->(DBSkip())
                      EndDo
                      If !_lTemSaldo
                          _lRet := .F.
                          Help( ,, 'Atenção',, 'Não é permitido este Tipo de ocorrência de frete pois não há saldo nos titulos para prorrogação.' , 1, 0 , .F.,,,,,{"Selecione outro tipo de ocorrencia."})
                      EndIf
                   Else
                      _lRet := .F.
                      Help( ,, 'Atenção',, 'Não é permitido este Tipo de ocorrência de frete pois não há titulos para prorrogação.' , 1, 0 , .F.,,,,,{"Selecione outro tipo de ocorrencia."})
                   EndIf
                ElseIf !__cUserId $ _cUsersHab .And. _oModelGrid:GetValue("ZF5_DPRORR") > 0
                   _lRet := .F.
                   Help( ,, 'Atenção',, 'Usuário sem permissão para utilizar este tipo de ocorrencia.' , 1, 0 , .F.,,,,,{"Para habilitar a utilização comunique o administrador do sistema."})
                EndIf
             EndIf
          EndIf
       EndIf
    EndIf
    
    //COLOQUE VALIDAÇOES NOVAS ANTES DESSE If POIS ELE ALTERA O CAMPO ZF5_ESTONO, ZF5_MOTCUS E LEGENDA
    If _lRet .And. _cAction == 'DELETE'  .And. _nOperation == MODEL_OPERATION_UPDATE .And. !_oModelGrid:IsInserted()
       _cTipoOcorr := _oModelGrid:GetValue("ZF5_TIPOO")
       _cDtTran    :=  Posicione("ZFC",1,xFilial("ZFC")+_cTipoOcorr,"ZFC_DTTRAN") // 1 = ZFC_FILIAL+ZFC_CODIGO
       If _cDtTran $ "A,B,C,D,E,F"
          If _oModelGrid:GetValue("ZF5_ESTONO") = "S"
             _oModelGrid:SetValue("ZF5_ESTONO","N")
             _oModelGrid:SetValue("ZF5_MOTCUS","Estorno Cancelado em "+DToC(Date())+" "+SubStr(Time(),1,5)+" por "+Capital( AllTrim( UsrFullName( __cUserId ) ) ) )
             U_ITMsg( 'Cancelamento do estorno da Ocorrencia feito com sucesso.' ,'Atenção',;
                      "caso necessario, aperte o DEL nessa ocorrência novamente para estornar-lá.",2,,,.T.)
          Else
             _oModelGrid:SetValue("ZF5_ESTONO","S")
             _oModelGrid:SetValue("ZF5_MOTCUS","Estornado em "+DToC(Date())+" "+SubStr(Time(),1,5)+" por "+Capital( AllTrim( UsrFullName( __cUserId ) ) ) )
             U_ITMsg( 'Ocorrencia estornada com sucesso.' ,'Atenção',;
                      "caso necessario, aperte o DEL nessa ocorrência novamente para cancelar o estorno.",2,,,.T.)
          EndIf
          _oModelGrid:SetValue("LEGENDA",AOMS03Leg(.T.))// REGRAVA A LEGENDA
          _lRet:= .F.
       EndIf
    EndIf
    //COLOQUE VALIDAÇOES NOVAS ANTES DESSE If ACIMA POIS ELE ALTERA O CAMPO ZF5_ESTONO E LEGENDA
    
 End Sequence

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS003E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/06/2016
Descrição---------: Pré validação da exclusão de ocorrências.
Parametros--------: _oModel = Modelo de Dados
Retorno-----------: True (.T.) ou False(.F.)
===============================================================================================================================
*/
User Function AOMS003E(_oModel)
 Local _lRet := .T.
 Local _nOperation := _oModel:GetOperation()
 Local _oModelGrid := _oModel:GetModel("ZF5DETAIL")
 Local _nI, _cSituacao

 Begin Sequence
    If _nOperation == MODEL_OPERATION_DELETE
       For _nI := 1 To _oModelGrid:Length()
           _oModelGrid:GoLine(_nI)
           _cEstonado:= _oModelGrid:GetValue("ZF5_ESTONO",_nI)
           If _cEstonado = "S" //SE ESTORNADO NÃO LE
              Loop
           EndIf
           _cSituacao := _oModelGrid:GetValue('ZF5_APRREJ')

           If ! Empty(_cSituacao)
              _lRet := .F.
              Help( ,, 'Atenção',, 'Não permitido apagar ocorrências de frete rejeitadas ou aprovadas.' ,1, 0 , .F. )
              Exit
           EndIf
       Next nI
    EndIf

 End Sequence

Return _lRet

/*
===============================================================================================================================
Programa--------: AOMS003R
Autor-----------: Julio de Paula Paz
Data da Criacao-: 18/07/2016
Descrição-------: Verifica se realmente houve alterações na linha de grid posicionada. Ou seja, se há diferença entre os dados
                  da tela e os dados gravados na base de dados.
Parametros------:  _oModelGrid = Modelo do grid de dados
                   _nLinha     = Numero da linha posicionada
Retorno   ------: True ou False.
===============================================================================================================================
*/
User Function AOMS003R( _oModel, _nLinha)

 Local _lRet := .F.
 Local _aOrd := SaveOrd({"ZF5"})
 Local _nRegAtu := ZF5->(Recno())
 Local _nI
 Local _oModelMaster := _oModel:GetModel("ZF5MASTER")
 Local _oModelGrid   := _oModel:GetModel("ZF5DETAIL")
 Local _aCpoDetail  := {}
 Local _nTotCampos
 Local _cNotaFiscal, _cSerie, _cCodigo

 Begin Sequence
    ZF5->(DBSetOrder(4)) // ZF5_FILIAL+ZF5_DOCOC+ZF5_SEROC+ZF5_CODIGO
    _nTotCampos := ZF5->(FCount())

    For _nI := 1 To _nTotCampos
        If AOMS003CPO(AllTrim(ZF5->(FieldName(_nI))) , 2 )
            aAdd(_aCpoDetail, AllTrim(ZF5->(FieldName(_nI))))
        EndIf
    Next _nI

   _cNotaFiscal := _oModelMaster:GetValue("ZF5_DOCOC")
   _cSerie      := _oModelMaster:GetValue("ZF5_SEROC")
   _cCodigo     := _oModelGrid:GetValue("ZF5_CODIGO")

   If ZF5->(DBSeek(xFilial("ZF5")+_cNotaFiscal+_cSerie+_cCodigo))
      For _nI := 1 To Len(_aCpoDetail)
          // Compara o conteúdo dos campos da base de dados com o conteúdo dos campos de grid,
          // e informa se houve alteração.
          If ZF5->&(_aCpoDetail[_nI]) <> _oModelGrid:GetValue(_aCpoDetail[_nI])
             _lRet := .T.
             Break
          EndIf
      Next _nI
   EndIf

 End Sequence

 RestOrd(_aOrd)
 ZF5->(DBGoTo(_nRegAtu))

Return _lRet

/*
===============================================================================================================================
Programa--------: AOMS003I
Autor-----------: Josué Danich Prestes
Data da Criacao-: 18/07/2016
Descrição-------: Gatilhos do campo de status
Parametros------:  Nenhum
Retorno   ------: _vret - Dados para campo gatilhado
===============================================================================================================================
*/
User Function AOMS003I()

 Local _vret
 Local _oModel
 Local _oModelMaster
 Local _oModelGrid

 _oModel      := FwModelActivete()
 _oModelMaster := _oModel:GetModel("ZF5MASTER")
 _oModelGrid   := _oModel:GetModel("ZF5DETAIL")

 If  !isincallstack("U_AOMS072")


   If Posicione("ZFD",1,xFilial("ZFD")+M->ZF5_STATUS,"ZFD_STATUS") == "E" .And. Empty(_oModelGrid:GetValue("ZF5_USRFIN"))

         _vret := __cUserId
         _oModelGrid:SetValue('ZF5_HRFIN',time())
         _oModelGrid:SetValue('ZF5_DTFIN',date())
           _oModelGrid:SetValue('ZF5_USRFIN', _vret)
         _oModelGrid:SetValue('ZF5_USNFIN', UsrFullName(_vret))

   ElseIf Posicione("ZFD",1,xFilial("ZFD")+M->ZF5_STATUS,"ZFD_STATUS") == "E"

         _vret := _oModelGrid:GetValue("ZF5_USRFIN")

   ElseIf Posicione("ZFD",1,xFilial("ZFD")+M->ZF5_STATUS,"ZFD_STATUS") != "E"

         _vret := "    "
         _oModelGrid:SetValue('ZF5_HRFIN',"   ")
         _oModelGrid:SetValue('ZF5_DTFIN',ctod(" / / "))
           _oModelGrid:SetValue('ZF5_USRFIN', "   ")
         _oModelGrid:SetValue('ZF5_USNFIN', "   ")

   EndIf

 Else
     nPosusrf := aScan(aHeader,{|x| AllTrim(x[2]) == "ZF5_USRFIN"})
     nPosdtf := aScan(aHeader,{|x| AllTrim(x[2]) == "ZF5_DTFIN"})
     nPoshrf := aScan(aHeader,{|x| AllTrim(x[2]) == "ZF5_HRFIN"})
     nPosusnf := aScan(aHeader,{|x| AllTrim(x[2]) == "ZF5_USNFIN"})

     If Posicione("ZFD",1,xFilial("ZFD")+M->ZF5_STATUS,"ZFD_STATUS") == "E" .And. Empty(acols[n][nposusrf])

         _vret := __cUserId
         acols[n][nPoshrf] := Time()
         acols[n][nPosdtf] := Date()
           acols[n][nPosusrf] :=  _vret
         acols[n][nPosusnf] := UsrFullName(_vret)

   ElseIf Posicione("ZFD",1,xFilial("ZFD")+M->ZF5_STATUS,"ZFD_STATUS") == "E"

         _vret := acols[n][nPosusrf]

   ElseIf Posicione("ZFD",1,xFilial("ZFD")+M->ZF5_STATUS,"ZFD_STATUS") != "E"

         _vret := "    "
         acols[n][nPoshrf] := " "
         acols[n][nPosdtf] := SToD(" ")
           acols[n][nPosusrf] :=  "  "
         acols[n][nPosusnf] := "  "

   EndIf

 EndIf

Return _vret

/*
===============================================================================================================================
Programa--------: AOMS003X
Autor-----------: Julio de Paula Paz
Data da Criacao-: 26/10/2017
Descrição-------: Valida e não permite a digitação de caracteres especiais de acordo com o conteúdo passado por parâmetro.
Parametros------: _cDados = informação a ser validada.
Retorno   ------: .T. = Os dados estão corretos. / .F. = Existe caracteres especiais nos dados validados.
===============================================================================================================================
*/
User Function AOMS003X(_cDados)
 Local _lRet := .T.
 Local _nI
 Local _cListaChar
 Local _cDigito

 Begin Sequence
    If Empty(_cDados)
       Break
    EndIf

    _cDados := AllTrim(_cDados)
    _cListaChar := "0123456789 ABCDEFGHIJKLMNOPQRSTUVXYWZ"

    For _nI := 1 To Len(_cDados)
        _cDigito := Upper(SubStr(_cDados,_nI,1))

        If ! _cDigito $ _cListaChar
           _lRet := .F.
           Help( ,, 'Atenção',, 'Não é permitido a digitação de caracteres especiais neste campo. Neste campo só é permitido a digitação de letras, numeros e espaços.', 1, 0, .F. )

           Break
        EndIf
    Next _nI

 End Sequence

Return _lRet


/*
===============================================================================================================================
Programa--------: AOMS03M
Autor-----------: Alex Wallauer
Data da Criacao-: 28/11/2017
Descrição-------: Encerrar varias ocorrenias
Parametros------: _lAtuTel
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS03M(_lAtuTel)

 Local C
 Local _nI, _cExpr

 Private cAliasAux	:= GetNextAlias(),_cArqTrab
 Private aHeader := {}
 Private aCols   := {}
 Private _lUsaMVC    := .F.
 Private _cNomeFonte := "AOMS003"

 If _lAtuTel
    aCampos:={"ZF5_STATUS","ZF5_STATUD","ZF5_DOCOC" ,"ZF5_SEROC" ,"ZF5_DMOTOR","ZF5_NREPRE","ZF5_NCOOR","ZF5_NCLIEN","ZF5_DATAE",;
              "ZF5_USNINI","ZF5_PEDIDO","ZF5_CLIENT","ZF5_LOJA"  ,"ZF5_MOTCUS","ZF5_ASSNOM","ZF5_CARGA","ZF5_DTINI" ,"ZF5_HRINI",;
              "ZF5_CODIGO","ZF5_TIPOO" ,"ZF5_MOTIVO","ZF5_AGENDA","ZF5_NTRANS","ZF5_TIPOC"}
 Else
    aCampos:={"ZF5_STATUS","ZF5_STATUD","ZF5_DOCOC" ,"ZF5_SEROC" ,"ZF5_DATAE" ,"ZF5_ASSNOM","ZF5_CARGA","ZF5_DTINI" ,"ZF5_HRINI" ,;
              "ZF5_USNINI","ZF5_PEDIDO","ZF5_CLIENT","ZF5_LOJA"  ,"ZF5_NCLIEN","ZF5_NREPRE","ZF5_NCOOR","ZF5_DMOTOR","ZF5_MOTCUS",;
              "ZF5_CODIGO","ZF5_TIPOO" ,"ZF5_MOTIVO","ZF5_AGENDA","ZF5_NTRANS","ZF5_TIPOC"}
 EndIf
 Private _cPerg := "AOMS003"

 // Valida a parametrização inicial e chama função para montagem da tela para
 // seleção das NF que terão os recebimentos de canhoto informados.
 If Pergunte(_cPerg,.T.)
    lRet:=.T.
    Processa( {|| lRet:=AOMS03P(.F.,_lAtuTel) } )
    If !lRet
       U_ITMsg("Sem registros para essa seleção de dados","Atenção",,3)
       Return
    EndIf
 Else
   Return
 EndIf

 FillGetDados(1,"ZF5",1,,,{||.T.},,,,,,.T.)

 _aFields:={}
 For C :=  1 TO Len(aCampos)
     _cCampo := PadR(aCampos[C],10)

     _nI := aScan(aHeader,{|x| AllTrim(x[2]) == AllTrim(_cCampo)})

     If _nI > 0

        _cExpr := U_AOMS03T(AllTrim(_cCampo))

        If _lAtuTel
           If AllTrim(_cCampo) $ "ZF5_DMOTOR/ZF5_NREPRE/ZF5_NCOOR/ZF5_NCLIEN"
              aAdd(_aFields,{ AllTrim( aHeader[_nI,1] )+" ( Tel. Atual )"      , aHeader[_nI,2], aHeader[_nI,8] , aHeader[_nI,4],aHeader[_nI,5],aHeader[_nI,3]})//+" Atual"
              If !Empty(_cExpr)
                 _cBox:="{||" + _cExpr + "}"                                                                 //  Picture 0,Tamanho Decimal
                 aAdd(_aFields,{AllTrim(aHeader[_nI,1] )+" ( Tel. Atualizado )", &(_cBox)      , aHeader[_nI,8] ,"@!"   ,0,50     ,0      })
              EndIf
              Loop
           EndIf
        EndIf

        If Empty(_cExpr)// Titulo                      Campo           Tipo             Tamanho        Decimal         Picture
           aAdd(_aFields,{ AllTrim( aHeader[_nI,1] ) , aHeader[_nI,2], aHeader[_nI,8] , aHeader[_nI,4],aHeader[_nI,5],aHeader[_nI,3]})
        Else
           _cBox:="{||" + _cExpr + "}"
           //              Titulo                     Codeblock Tipo           Picture 0,Tamanho Decimal
           aAdd(_aFields,{ AllTrim( aHeader[_nI,1] ), &(_cBox) ,aHeader[_nI,8],"@!"   ,0,50     ,0      })
        EndIf


     EndIf
 Next C

 aHeader := {}
 aCols   := {}

 (cAliasAux)->( DBGoTop() )
 oMarkBRW:=FWMarkBrowse():New()		   											// Inicializa o Browse
 oMarkBRW:SetAlias( cAliasAux )			   										// Define Alias que será a Base do Browse
 oMarkBRW:SetDescription( "Ocorrencias de frete para ATUALIZAR TELEFONES" )	// Define o titulo do browse de marcacao
 oMarkBRW:SetFieldMark( "MARCA" )												// Define o campo que sera utilizado para a marcação
 oMarkBRW:SetMenuDef( 'XXXXXX' )													// Força a utilização do menu da rotina atual
 oMarkBRW:SetAllMark( {|| oMarkBRW:AllMark()} )									// Ação do Clique no Header da Coluna de Marcação

 If _lAtuTel
    oMarkBRW:SetValid( {|| ((cAliasAux)->STATUS2="S") } )
    oMarkBRW:AddLegend('(cAliasAux)->STATUS2="S"',"RED"  , "DIFERENTE")// Permite adicionar legendas no Browse
    oMarkBRW:AddLegend('(cAliasAux)->STATUS2="N"',"GREEN", "IGUAL"    )// Permite adicionar legendas no Browse
 Else
    oMarkBRW:AddLegend('Posicione("ZFD",1,xFilial("ZFD")+(cAliasAux)->ZF5_STATUS,"ZFD_STATUS")=="P"',"GREEN", "Pendente"     )// Permite adicionar legendas no Browse
    oMarkBRW:AddLegend('Posicione("ZFD",1,xFilial("ZFD")+(cAliasAux)->ZF5_STATUS,"ZFD_STATUS")=="E"',"RED",   "Efetivado"    )// Permite adicionar legendas no Browse
    oMarkBRW:AddLegend('Posicione("ZFD",1,xFilial("ZFD")+(cAliasAux)->ZF5_STATUS,"ZFD_STATUS")=="N"',"GRAY",  "Não Procede"  )// Permite adicionar legendas no Browse
    oMarkBRW:AddLegend('Posicione("ZFD",1,xFilial("ZFD")+(cAliasAux)->ZF5_STATUS,"ZFD_STATUS")=="T"',"YELLOW","Em tratamento")// Permite adicionar legendas no Browse
 EndIf
 oMarkBRW:SetFields( _aFields )													 		// Campos para exibição
 oMarkBRW:AddButton( "Confirmar"         , {|| Processa( {|| lRet:=AOMS03P(.T.,_lAtuTel) } )  } ,, 4 )// Adiciona um botão na área lateral do Browse //, If(lRet,oMarkBRW:DeActivate(),)
 oMarkBRW:DisableConfig()                                                                // Desabilita a utilização das configurações do Browse
 oMarkBRW:Activate()																		// Ativacao da classe

 (cAliasAux)->( DBCloseArea() )

Return .F.


/*
===============================================================================================================================
Programa--------: AOMS03P
Autor-----------: Alex Wallauer
Data da Criacao-: 28/11/2017
Descrição-------: Encerrar vairas ocorrenias
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS03P(_lGravar,_lAtuTel)
 
 Local _aCpos := {}
 Local _cQuery:= "",_nTot:=0
 Local _cNomeArq, _cCodFilial
 Local _cNomeCpo, _nI, _cCampoWork, _cCampoZF5
 Local _cNomeUsr, _vret

 ProcRegua(4)

 If _lGravar

    If (_lAtuTel .And. U_ITMsg("Confirma o ATUALIZACAO dos registros Marcados?",'Atenção!',,2,2,2)) .OR.;
       (!_lAtuTel .And. U_ITMsg("Confirma o ENCERRAMENTO dos registros Marcados?",'Atenção!',,2,2,2))

       IncProc("Gravando dados ...")
       _nTot:=0
       IncProc("Gravando dados ...")
       ProcRegua((cAliasAux)->(LASTREC()))
       (cAliasAux)->(DBGoTop())
       nRecAux:=(cAliasAux)->( Recno() )

       _vret := __cUserId
       _cNomeUsr := UsrFullName(_vret)

       While (cAliasAux)->(!Eof())

          IncProc("Gravando dados ...")

           oMarkBRW:GoTo( (cAliasAux)->( Recno() ) , .F. )

             If oMarkBRW:IsMark()

             nRecAux:=(cAliasAux)->( Recno() )
             If _lAtuTel
                oMarkBRW:GoTo( (cAliasAux)->( Recno() ) , .T. )
                ZF5->(DBGoTo( (cAliasAux)->REC_ZF5 ))
                ZF5->(RecLock("ZF5",.F.))
                U_AOMS3Atu(.T.)
             Else
                ZF5->(DBGoTo( (cAliasAux)->REC_ZF5 ))
                ZF5->(RecLock("ZF5",.F.))
                ZF5->ZF5_STATUS:="000001"
                ZF5->ZF5_HRFIN := Time()
                ZF5->ZF5_DTFIN := Date()
                ZF5->ZF5_USRFIN:= _vret
                ZF5->ZF5_USNFIN:= _cNomeUsr
             EndIf
             ZF5->(MSUnLock())
             _nTot++
             If !_lAtuTel
                (cAliasAux)->(DBDELETE())
             EndIf

          EndIf
          (cAliasAux)->(DBSkip())

       EndDo

    EndIf

    (cAliasAux)->(DBGoTop())
     oMarkBRW:GoTo( nRecAux , .T. )

    If _nTot > 0
       If _lAtuTel
          U_ITMsg("Registros atualizados: "+AllTrim(Str(_nTot)),"Atenção",,2)
       Else
          U_ITMsg("Registros encerrados: "+AllTrim(Str(_nTot)),"Atenção",,2)
       EndIf
    Else
       U_ITMsg("Não foram marcados registros","Atenção",,1)
    EndIf

    Return _nTot > 0

 EndIf

 _aCpos := FWSX3Util():GetListFieldsStruct( "ZF5" , .T.  )//Com campos virtuais
 aAdd( _aCpos , { "REC_ZF5", "N" , 10, 0 } )
 aAdd( _aCpos , { "MARCA"  , "C" , 01, 0 } )
 aAdd( _aCpos , { "STATUS2", "C" , 01, 0 } )

 IncProc("1-Lendo dados ...")

 _oTemp2:= FWTemporaryTable():New(cAliasAux, _aCpos )
 _oTemp2:Create()

 _cQuery	:= " SELECT R_E_C_N_O_ REC_ZF5 "
 _cNomeArq  := RetSqlName("ZF5")
 _cQuery  	+= " FROM " + _cNomeArq + " ZF5"
 _cCodFilial:= xFilial("ZF5")
 _cQuery  	+= " WHERE ZF5.ZF5_FILIAL = '" + _cCodFilial + "'"
 _cQuery   	+= " AND ZF5.ZF5_DTFIN = '  ' AND ZF5.ZF5_NDEBIT <> 'S' "

 If !Empty(MV_PAR03)
    _cQuery += " AND ZF5.ZF5_CLIENT = '" + MV_PAR03 + "'
 EndIf

 If !Empty(MV_PAR03) .And. !Empty(MV_PAR04)
    _cQuery  += " AND ZF5.ZF5_LOJA = '" + MV_PAR04 + "'
 EndIf

 If !Empty(MV_PAR05) .And. !Empty(MV_PAR06)
    _cQuery  += " AND ZF5.ZF5_DTINI BETWEEN '" + DToS(MV_PAR05) + "' AND '" + DToS(MV_PAR06) + "' "
 EndIf

 _cQuery  	+= " AND ZF5.D_E_L_E_T_ = ' ' AND ZF5.ZF5_STATUS IN ("
 _cQuery	+= " SELECT ZFD.ZFD_CODIGO "
 _cNomeArq  := RetSqlName("ZFD")
 _cQuery  	+= " FROM " + _cNomeArq + " ZFD"
 _cCodFilial:= xFilial("ZFD")
 _cQuery  	+= " WHERE ZFD.ZFD_FILIAL = '" + _cCodFilial + "'"
 _cQuery   	+= " AND ZFD.ZFD_STATUS <> 'E' "
 _cQuery  	+= " AND ZFD.D_E_L_E_T_ = ' ' )"

 If !Empty(MV_PAR02)
    _cQuery  	+= " AND ZF5.ZF5_DOCOC IN ("
    _cQuery	    += " SELECT SF2.F2_DOC "
    _cNomeArq   := RetSqlName("SF2")
    _cQuery  	+= " FROM " + _cNomeArq + " SF2"
    _cCodFilial := xFilial("SF2")
    _cQuery  	+= " WHERE SF2.F2_FILIAL = '" + _cCodFilial + "'"
    _cQuery  	+= " AND SF2.F2_EMISSAO BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "' "
    _cQuery  	+= " AND SF2.D_E_L_E_T_ = ' ' )"
 EndIf
 _cQuery += " ORDER BY ZF5.ZF5_DTINI,ZF5.ZF5_DOCOC "

 cAlias:=GetNextAlias()
 MPSysOpenQuery( _cQuery , cAlias)

 IncProc("2-Lendo dados ...")

 DBSelectArea(cAlias)
 Count to _nTot

 IncProc("3-Lendo dados ...")

 ProcRegua(_nTot)

 (cAlias)->(DBGoTop())

 While (cAlias)->(!Eof())

    IncProc("4-Lendo dados ...")
    ZF5->(DBGoTo( (cAlias)->REC_ZF5 ))

    (cAliasAux)->( DBAPPEND() )

    For _nI := 1 To ZF5->(FCount())
        _cNomeCpo := ZF5->(FieldName(_nI))
        If (cAliasAux)->(FieldPos(_cNomeCpo)) > 0
           _cCampoWork := cAliasAux + "->" + _cNomeCpo
           _cCampoZF5  := "ZF5->" + _cNomeCpo
           &(_cCampoWork) := &(_cCampoZF5)
        EndIf
    Next _nI
    If _lAtuTel
       (cAliasAux)->STATUS2:="N"//Algum Diferente? NÃO
       If AllTrim((cAliasAux)->ZF5_DMOTOR) <> AllTrim(U_AOMS003Z("ZF5_DMOTOR")) .OR.;
          AllTrim((cAliasAux)->ZF5_NREPRE) <> AllTrim(U_AOMS003Z("ZF5_NREPRE")) .OR.;
          AllTrim((cAliasAux)->ZF5_NCOOR ) <> AllTrim(U_AOMS003Z("ZF5_NCOOR" )) .OR.;
          AllTrim((cAliasAux)->ZF5_NCLIEN) <> AllTrim(U_AOMS003Z("ZF5_NCLIEN"))
          (cAliasAux)->STATUS2:="S"//Algum Diferente? SIM
       EndIf
    EndIf

    (cAliasAux)->REC_ZF5:=(cAlias)->REC_ZF5

    (cAlias)->(DBSkip())

 EndDo

 (cAlias)->(DBCloseArea() )

Return _nTot > 0

/*
===============================================================================================================================
Programa--------: AOMS03T
Autor-----------: Julio de Paula Paz
Data da Criacao-: 23/11/2018
Descrição-------: Retornar as Strings com funções que exibirão dados na função FWMBrowse.
Parametros------: _cNomeCampo = Nome do campo que deve ter a String com função retornada.
Retorno---------: _cRet = String com a função que deve ser retornada.
===============================================================================================================================
*/
User Function AOMS03T(_cNomeCampo)
   Local _cRet := ""
   If AllTrim(_cNomeCampo) $ "ZF5_DMOTOR/ZF5_NREPRE/ZF5_NCOOR/ZF5_NCLIEN"
      _cRet := 'U_AOMS003Z("'+AllTrim(_cNomeCampo)+'",3)'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_DATAE"
      //_cRet := 'U_AOMS003Z("ZF5_DATAE")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_ASSNOM"
      //_cRet := 'U_AOMS003Z("ZF5_ASSNOM")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_PEDIDO"
      //_cRet := 'U_AOMS003Z("ZF5_PEDIDO")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_DTCAR"
      //_cRet := 'U_AOMS003Z("ZF5_DTCAR")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_STATUD"
      _cRet := 'Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_DESCRI")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_CLIENT"
      //_cRet := 'U_AOMS003Z("ZF5_CLIENT")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_LOJA"
      //_cRet := 'U_AOMS003Z("ZF5_LOJA")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_NCLIEN"
      //_cRet := 'U_AOMS003Z("ZF5_NCLIEN")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_VOLUM"
      //_cRet := 'U_AOMS003Z("ZF5_VOLUM")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_REPRES"
      //_cRet := 'U_AOMS003Z("ZF5_REPRES")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_NREPRE"
      //_cRet := 'U_AOMS003Z("ZF5_NREPRE")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_PESO"
      //_cRet := 'U_AOMS003Z("ZF5_PESO")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_PESON"
      //_cRet := 'U_AOMS003Z("ZF5_PESON")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_COORD"
      //_cRet := 'U_AOMS003Z("ZF5_COORD")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_NCOOR"
      //_cRet := 'U_AOMS003Z("ZF5_NCOOR")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_VLRFRE"
      //_cRet := 'U_AOMS003Z("ZF5_VLRFRE")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_UF"
      //_cRet := 'U_AOMS003Z("ZF5_UF")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_MOTORI"
      //_cRet := 'U_AOMS003Z("ZF5_MOTORI")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_DMOTOR"
      //_cRet := 'U_AOMS003Z("ZF5_DMOTOR")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_CIDADE"
      //_cRet := 'U_AOMS003Z("ZF5_CIDADE")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_VEICUL"
      //_cRet := 'U_AOMS003Z("ZF5_VEICUL")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_DVEICU"
      //_cRet := 'U_AOMS003Z("ZF5_DVEICU")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_PLACA"
      //_cRet := 'U_AOMS003Z("ZF5_PLACA")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_TIPOV"
      //_cRet := 'U_AOMS003Z("ZF5_TIPOV")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_TRANSP"
      //_cRet := 'U_AOMS003Z("ZF5_TRANSP")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_NTRANS"
      //_cRet := 'U_AOMS003Z("ZF5_NTRANS")'
   ElseIf AllTrim(_cNomeCampo) =  "ZF5_STATE"
      _cRet := 'U_AOMS003U("ZF5_STATE")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_STATC"
      _cRet := 'U_AOMS003U("ZF5_STATC")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_TIPOV"
      _cRet := 'U_AOMS003U("ZF5_TIPOV")'
   ElseIf AllTrim(_cNomeCampo) == "ZF5_TIPOC"
      _cRet := 'U_AOMS003U("ZF5_TIPOC")'
      _lEnviou := .F.
   ElseIf AllTrim(_cNomeCampo) == "ZF5_SEROC"
      //_cRet := 'U_AOMS003U("ZF5_SEROC")'
   EndIf
Return _cRet

/*
===============================================================================================================================
Programa--------: AOMS003U
Autor-----------: Julio de Paula Paz
Data da Criacao-: 23/11/2018
Descrição-------: Retornar as Strings relacionada aos parâmetros passados pela função.
Parametros------: _cNomeCampo = Nome do campo que deve retornar uma String.
Retorno---------: _cRet = String com a função que deve ser retornada.
===============================================================================================================================
*/
User Function AOMS003U(_cNomeCampo)
    Local _cRet := ""
    ZF5->(DBGoTo( (cAliasAux)->REC_ZF5 ))

    If AllTrim(_cNomeCampo) == "ZF5_STATE"
       If ZF5->ZF5_STATE == "V"
          _cRet := "Valor"
       ElseIf ZF5->ZF5_STATE == "F"
          _cRet := "Formula"
       ElseIf ZF5->ZF5_STATE == "P"
          _cRet := "Percentual"
       EndIf

    ElseIf AllTrim(_cNomeCampo) == "ZF5_STATC"
       If ZF5->ZF5_STATC == "P"
          _cRet := "Pendente"
       ElseIf ZF5->ZF5_STATC == "T"
          _cRet := "Tratamento"
       ElseIf ZF5->ZF5_STATC == "E"
          _cRet := "Encerrado"
       ElseIf ZF5->ZF5_STATC == "S"
          _cRet := "Sem custo"
       EndIf

    ElseIf AllTrim(_cNomeCampo) == "ZF5_TIPOV"
       If ZF5->ZF5_TIPOV == "1"
          _cRet :="CARRETA"
       ElseIf ZF5->ZF5_TIPOV == "2"
          _cRet := "CAMINHAO"
       ElseIf ZF5->ZF5_TIPOV == "3"
          _cRet :=   "BI-TREM"
       ElseIf ZF5->ZF5_TIPOV == "4"
          _cRet := "UTILITARIO"
       ElseIf ZF5->ZF5_TIPOV  == "5"
          _cRet := "RODOTREM"
       EndIf

    ElseIf AllTrim(_cNomeCampo) == "ZF5_TIPOC"
       If ZF5->ZF5_TIPOC == "M"
          _cRet := "Misto"
       ElseIf ZF5->ZF5_TIPOC == "I"
          _cRet := "Italac"
       ElseIf ZF5->ZF5_TIPOC == "T"
          _cRet := "Transportador"
       ElseIf ZF5->ZF5_TIPOC == "R"
          _cRet := "Representante"
       ElseIf ZF5->ZF5_TIPOC == "C"
          _cRet := "Cliente"
       ElseIf ZF5->ZF5_TIPOC == "3"
          _cRet := "Terceiros"
       EndIf
    EndIf
Return _cRet

/*
===============================================================================================================================
Programa--------: AOMS003DT
Autor-----------: Josué Danich Prestes
Data da Criacao-: 26/12/2018
Descrição-------: Exclui título de débito de transporte
Parametros------: nRecZF5 - recno do ZF5 a limpar
                 _oModelGrid - objeto
Retorno---------: _lretorno - Se excluiu com sucesso
===============================================================================================================================
*/
Static Function AOMS003DT(nRecZF5,_oModelGrid)

 Local _lretorno := .F.
 Local _aAutoSE2 := {}
 Local _aAreaSA2 := {}
 Local _lBloq := .F.

 aAdd( _aAutoSE2 , { "E2_FILIAL"    , SE2->E2_FILIAL     , nil } )
 aAdd( _aAutoSE2 , { "E2_PREFIXO"   , SE2->E2_PREFIXO , nil } )
 aAdd( _aAutoSE2 , { "E2_NUM"       , SE2->E2_NUM	     , nil } )
 aAdd( _aAutoSE2 , { "E2_PARCELA"	, SE2->E2_PARCELA    , nil } )
 aAdd( _aAutoSE2 , { "E2_TIPO"		, SE2->E2_TIPO	     , nil } )
 aAdd( _aAutoSE2 , { "E2_NATUREZ"	, SE2->E2_NATUREZ    , nil } )
 aAdd( _aAutoSE2 , { "E2_FORNECE"	, SE2->E2_FORNECE    , nil } )
 aAdd( _aAutoSE2 , { "E2_LOJA"		, SE2->E2_LOJA	     , nil } )
 aAdd( _aAutoSE2 , { "E2_EMISSAO"	, SE2->E2_EMISSAO    , nil } )
 aAdd( _aAutoSE2 , { "E2_VENCTO"    , SE2->E2_VENCTO     , nil } )
 aAdd( _aAutoSE2 , { "E2_VALOR"     , SE2->E2_VALOR      , nil } )
 aAdd( _aAutoSE2 , { "E2_HIST"		, SE2->E2_HIST       , Nil } )
 aAdd( _aAutoSE2 , { "E2_DATALIB"	, SE2->E2_DATALIB    , nil } )
 aAdd( _aAutoSE2 , { "E2_USUALIB"	, SE2->E2_USUALIB    , nil } )

 lMsErroAuto := .F.
 _cAOMS074Vld:= ""
 _cAOMS074 :="AOMS103"
 _ce2num   := SE2->E2_NUM
 _cFornece := SE2->E2_FORNECE
 _cLoja    := SE2->E2_LOJA
 _cSeekSE2 := SE2->E2_FILIAL+SE2->E2_PREFIXO+SE2->E2_NUM+SE2->E2_PARCELA+SE2->E2_TIPO+SE2->E2_FORNECE+SE2->E2_LOJA

 If nRecZF5 > 0
    ZF5->(DBGoTo(nRecZF5))
 EndIf
 _cCodigo  := ZF5->ZF5_CODIGO
 _aAreaSA2 := GetArea("SA2")

 SA2->( DBSetOrder(1) )
 If SA2->(DBSeek( xFilial('SA2') + AllTrim(_cfornece) + AllTrim(_cloja) ))
     If SA2->A2_MSBLQL == '1'
         Help( ,, 'Atenção',, 'Erro ao excluir título: ' + SE2->E2_NUM + ' Parc.:' + SE2->E2_PARCELA + ' de nota de débito. Fornecedor informado ' + AllTrim(_cfornece) + " - " + AllTrim(_cloja) + ' encontra-se Bloqueado ou Inativo no cadastro de Fornecedores do Sistema!' , 1, 0, .F. )
       _lBloq := .T.
     Else
       _lBloq := .F.
    EndIf
 EndIf

 FWRestArea(_aAreaSA2)

 If _lBloq
    _lretorno := .F.
 Else
    _nModAux  := nModulo
    _cModAux  := cModulo
    nModulo   := 6
    cModulo   := "FIN"

    FWMsgRun(,{ || MSExecAuto({|v,h,k,l,m,n,o| Fina050(v,h,k,l,m,n,o)},_aAutoSE2,,5,,,.F.,.T.)},"Aguarde...", "Excluindo título de nota de débito da Ocorrência " + StrZero(Val(_cCodigo),6)) //Exclusão

    If lMsErroAuto .Or. !Empty(_cAOMS074Vld)
       U_ITMsg('Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Erro ao exclui título de nota de débito, ocorrência não será salva. Print essa e a proxima tela.','Atenção!',_cAOMS074Vld,,,,.T.)  //HELP PARA O MVC
       MostraErro()
    Else

       SE2->(DBSetOrder(1))
       If !(SE2->(DBSeek(_cSeekSE2)))

           //Posiciona no registro gravado no banco para comparar
           If nRecZF5 > 0
              ZF5->(DBGoTo(nRecZF5))
              ZF5->(RecLock("ZF5",.F.))
              ZF5->ZF5_CHVNDT:=""
              ZF5->(MSUnLock())
             _oModelGrid:LoadValue('ZF5_CHVNDT',Space(Len(ZF5->ZF5_CHVNDT)))
          EndIf

           _lretorno := .T.
       Else
          //Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Erro ao excluir título de nota de débito, ocorrência não será salva/apagada.' , 1, 0 )
          //Não pode ser help senão sobrepõe a mensagem de help do erro do MSExecAuto/Fina050
          U_ITMsg('Ocorrência ' + StrZero(Val(_cCodigo),6)  + ' - Erro ao excluir título de nota de débito, ocorrência não será salva/apagada.','Atenção!',,1)
       EndIf

    EndIf

 EndIf

 nModulo := _nModAux
 cModulo := _cModAux

Return _lretorno

/*
===============================================================================================================================
Programa----------: AOMS003Y
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 18/04/2012
Descrição---------: Monta Tela para consulta de itens do documento de devolução selecionado F3
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS003Y()

 Local i            := 0
 Local _cAlias      := GetNextAlias()
 Local _oModel      := FwModelActivete()
 Local _oModelGrid  := _oModel:GetModel("ZF5DETAIL")
 Local _oModelMaster:= _oModel:GetModel("ZF5MASTER")

 Private nTam      := 0
 Private nMaxSelect:= 0
 Private aCat      := {}
 Private MvRet     := AllTrim(_oModelGrid:GetValue('ZF5_DVITEM'))
 Private MvPar     := ""
 Private cTitulo   := ""
 Private MvParDef  := ""

 M->ZF5_DVITEM := _oModelGrid:GetValue("ZF5_DVITEM")
 MvRet         := "M->ZF5_DVITEM"

 Begin Sequence

 //Identifica fornecedor de nota de devolução
 If _oModelGrid:GetValue('ZF5_ORIDEV') != "I"

    _cforn := AllTrim(_oModelMaster:GetValue('ZF5_CLIENT'))
    _clojaf := AllTrim(_oModelMaster:GetValue('ZF5_LOJA'))

 Else

    _lachou := .F.
    ZZM->(DBSetOrder(1))
    If ZZM->(DBSeek(xFilial("ZZM")+cfilant))

       SA1->(DBSetOrder(3))
       If SA1->(DBSeek(xFilial("SA1")+AllTrim(ZZM->ZZM_CGC)))

          _lachou := .T.
          _cforn := AllTrim(SA1->A1_COD)
          _clojaf := AllTrim(SA1->A1_LOJA)

       EndIf

    EndIf

    If !_lachou

       U_ITMsg("Devolução de origem Italac para filial não localizada em cadastro de clientes.","Atenção",,1)
       Break

    EndIf

 EndIf


 //Tratamento para carregar variaveis da lista de opcoes
 nTam       := 4
 nMaxSelect := 20
 cTitulo    := "ITENS DO DOCUMENTO DE DEVOLUÇÃO"

 _cQuery := 	" SELECT	D1_ITEM,D1_COD"
 _cQuery +=	" FROM  " + retsqlname("SD1")
 _cQuery +=  " WHERE	D_E_L_E_T_ = ' ' "
 _cQuery +=  " AND	D1_FILIAL = '" + cfilant + "' AND D1_DOC = '" + AllTrim(_oModelGrid:GetValue('ZF5_DOCDEV')) + "' "
 _cQuery +=  " AND	D1_SERIE = '" +  AllTrim(_oModelGrid:GetValue('ZF5_SERDEV')) + "' "
 _cQuery +=  " AND	D1_FORNECE = '" + _cforn + "' AND D1_LOJA = '" + _clojaf + "' "
 _cQuery +=  " ORDER BY D1_ITEM "

 _cAlias:=GetNextAlias()
 MPSysOpenQuery( _cQuery , _cAlias )

 (_cAlias)->(DBGoTop())

 If (_cAlias)->(Eof())

    U_ITMsg("Documento de devolução não localizado.","Atenção","Verifique se o documento de devolução já foi classificado",1)
    Break

 EndIf

 While !(_cAlias)->(Eof())

     MvParDef += (_cAlias)->D1_ITEM
     aAdd(aCat,AllTrim((_cAlias)->D1_COD) + " - " +  Posicione("SB1",1,xFilial("SB1")+AllTrim((_cAlias)->D1_COD),"B1_DESC"))

    (_cAlias)->(DBSkip())
 EndDo

 (_cAlias)->(DBCloseArea())

 If Len(AllTrim(&MvRet)) == 0
     MvPar:= PadR(AllTrim(StrTran(&MvRet,"/","")),Len(aCat))
     &MvRet:= PadR(AllTrim(StrTran(&MvRet,"/","")),Len(aCat))
 Else
     MvPar:= AllTrim(StrTran(&MvRet,";","/"))
 EndIf

 //Executa funcao que monta tela de opcoes
 If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)

     //Tratamento para separar retorno com barra "/"
     &MvRet := ""
     For i:=1 to Len(MvPar) step nTam
         If !(SubStr(MvPar,i,1) $ " |*")
             &MvRet  += SubStr(MvPar,i,nTam) + "/"
         EndIf
     Next i

    _oModelGrid:LoadValue('ZF5_DVITEM',&MvRet)

 EndIf

 End Sequence

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS003A
Autor-------------: Josué Danich Prestes
Data da Criacao---: 02/04/2019
Descrição---------: Monta Tela para consulta de documentos de devolução do cliente selecionado
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS003A()

 Local _cAlias      := GetNextAlias()
 Local _oModel      := FwModelActivete()
 Local _oModelGrid  := _oModel:GetModel("ZF5DETAIL")
 Local _oModelMaster:= _oModel:GetModel("ZF5MASTER")

 Private nTam      := 0
 Private nMaxSelect:= 0
 Private aCat      := {}
 Private MvRet     := AllTrim(_oModelGrid:GetValue('ZF5_DOCDEV')) + "/" + AllTrim(_oModelGrid:GetValue('ZF5_SERDEV'))
 Private MvPar     := ""
 Private cTitulo   := ""
 Private MvParDef  := ""

 _cRetorno := AllTrim(_oModelGrid:GetValue('ZF5_DOCDEV')) + AllTrim(_oModelGrid:GetValue('ZF5_SERDEV'))

 M->ZF5_DOCDEV := _oModelGrid:GetValue("ZF5_DOCDEV")


 //Identifica fornecedor de nota de devolução
 If _oModelGrid:GetValue('ZF5_ORIDEV') != "I"

   _cforn := AllTrim(_oModelMaster:GetValue('ZF5_CLIENT'))
   _clojaf := AllTrim(_oModelMaster:GetValue('ZF5_LOJA'))

 Else

   _lachou := .F.
   ZZM->(DBSetOrder(1))
   If ZZM->(DBSeek(xFilial("ZZM")+cfilant))

      SA1->(DBSetOrder(3))
      If SA1->(DBSeek(xFilial("SA1")+AllTrim(ZZM->ZZM_CGC)))

         _lachou := .T.
         _cforn := AllTrim(SA1->A1_COD)
         _clojaf := AllTrim(SA1->A1_LOJA)

      EndIf

   EndIf

   If !_lachou

      U_ITMsg("Devolução de origem Italac para filial não localizada em cadastro de clientes.","Atenção",,1)
      Break

   EndIf

 EndIf


 //Tratamento para carregar variaveis da lista de opcoes
 nTam       := 13
 nMaxSelect := 1
 cTitulo    := "DOCUMENTOS DE DEVOLUÇÃO"
 _dlimit := Date() - 180

 _cQuery := 	" SELECT	F1_DOC,F1_SERIE,F1_EMISSAO"
 _cQuery +=	" FROM  " + retsqlname("SF1")
 _cQuery +=  " WHERE	D_E_L_E_T_ = ' ' "
 _cQuery +=  " AND	F1_FILIAL = '" + cfilant + "' AND F1_EMISSAO >= '" + DToS(_dlimit) + "' "
 _cQuery +=  " AND	F1_FORNECE = '" + _cforn + "' AND F1_LOJA = '" + _clojaf + "' "
 _cQuery +=  " ORDER BY F1_EMISSAO DEsC"

 MPSysOpenQuery( _cQuery , _cAlias )

 (_cAlias)->(DBGoTop())

 If (_cAlias)->(Eof())

    U_ITMsg("Documento de devolução não localizado.","Atenção","Verifique se o documento de devolução já foi classificado",1)
    Break

 EndIf

 While !(_cAlias)->(Eof())
     MvParDef += (_cAlias)->F1_DOC+"/"+(_cAlias)->F1_SERIE
     aAdd(aCat,AllTrim((_cAlias)->F1_DOC) + " - " + AllTrim((_cAlias)->F1_SERIE) + " - " + DToC(SToD(AllTrim((_cAlias)->F1_EMISSAO))) )
     (_cAlias)->(DBSkip())
 EndDo

 (_cAlias)->(DBCloseArea())

 //Executa funcao que monta tela de opcoes
 If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)

    mvpar := StrTran(mvpar,'*')
    _cRetorno := SubStr(MVPAR,1,9) + SubStr(MVPAR,11,3)

 EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS003B
Autor-------------: Josué Danich Prestes
Data da Criacao---: 02/04/2019
Descrição---------: Gatilho pós consulta no campo de documento de devolução
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS003B()

 Local _oModel:=FwModelActivete()
 Local _oModelGrid:=_oModel:GetModel("ZF5DETAIL")
 Local _cret:=_oModelGrid:GetValue('ZF5_SERDEV')

 If ValType(_cRetorno) == "C"
    _cret := SubStr(_cRetorno,10,3)
 EndIf

Return _cret

/*
===============================================================================================================================
Programa----------: AOMS003DP
Autor-------------: Josué Danich Prestes
Data da Criacao---: 02/04/2019
Descrição---------: Exclui pedido de descarte posicionado
Parametros--------: Nenhum (SC5 precisa estar posicionado)
Retorno-----------: _lRet - sucesso da operação
===============================================================================================================================
*/
Static Function AOMS003DP()

 Local _aCabcPVEX := {}
 Local _aItenPVEx := {}
 Local _oModel           := FwModelActivete()
 Local _oModelGrid       := _oModel:GetModel("ZF5DETAIL")
 Local _lRet := .F.
 Local _cCodUsu := "" As Character

 If !_lJob
    _cCodUsu	:= FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
 Else
    _cCodUsu	:= "SISTEMA"
 EndIf

 _aCabcPVEx := {		   { "C5_FILIAL"  , SC5->C5_FILIAL                 ,Nil},;
                                { "C5_NUM"     , SC5->C5_NUM         	,Nil},;
                                { "C5_TIPO"    , SC5->C5_TIPO    			,Nil},;
                                { "C5_CLIENTE" , SC5->C5_CLIENTE 			,Nil},;
                                { "C5_LOJACLI" , SC5->C5_LOJACLI 			,Nil},;
                                { "C5_CLIENT " , SC5->C5_CLIENT  			,Nil},; // Codigo do cliente
                                { "C5_LOJAENT" , SC5->C5_LOJAENT 			,Nil},; // Loja para entrada
                                { "C5_TIPOCLI" , SC5->C5_TIPOCLI 			,Nil},;
                                { "C5_CONDPAG" , SC5->C5_CONDPAG 			,Nil},;
                                { "C5_VEND1"   , SC5->C5_VEND1   			,Nil},;
                                { "C5_EMISSAO" , SC5->C5_EMISSAO        ,Nil},;
                                { "C5_TPFRETE" , SC5->C5_TPFRETE 			,Nil},;
                                { "C5_VOLUME1" , SC5->C5_VOLUME1 			,Nil},;
                                { "C5_ESPECI1" , SC5->C5_ESPECI1 			,Nil},;
                                { "C5_TPCARGA" , SC5->C5_TPCARGA 			,Nil},;
                                { "C5_I_AGEND" , SC5->C5_I_AGEND 			,Nil},;
                                { "C5_I_ENVRD" , "N"                		,Nil},;
                                { "C5_I_IDPED" , SC5->C5_I_IDPED			,Nil},;
                                { "C5_I_CDUSU" 	, _cCodUsu	            ,Nil }} // Codigo Usuario


 SC6->(DBSetOrder(1))
 If SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))

    While SC5->C5_NUM == SC6->C6_NUM .And. SC5->C5_FILIAL == SC6->C6_FILIAL

       aAdd( _aItenPVEx , {	{ "C6_FILIAL"  , SC6->C6_FILIAL	,Nil},;
                                                          { "C6_ITEM"    , SC6->C6_ITEM		,Nil},;
                                                          { "C6_PRODUTO" , SC6->C6_PRODUTO	,Nil},;
                                                          { "C6_QTDVEN"  , SC6->C6_QTDVEN	,Nil},;
                                                          { "C6_UM"      , SC6->C6_UM		,Nil},;
                                                          { "C6_PRCVEN"  , SC6->C6_PRCVEN	,Nil},;
                                                          { "C6_VALOR"   , SC6->C6_VALOR	,Nil},;
                                                          { "C6_PEDCLI"  , SC6->C6_PEDCLI	,Nil},;
                                                          { "C6_QTDLIB"  , SC6->C6_QTDLIB	,Nil},;
                                                          { "C6_LOCAL"   , SC6->C6_LOCAL	,Nil},;
                                                          { "C6_NUM"     , SC6->C6_NUM		,Nil}})

       SC6->(DBSkip())

    EndDo

 EndIf

 lMsErroAuto := .F.

 FWMsgRun(,{ || MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabcPVEx , _aItenPVEx , 5 )},"Aguarde","Excluindo pedido de descarte...")

 If lMsErroAuto

    MostraErro()
    Help( ,, 'Atenção',, 'Não foi possível excluir pedido de descarte, ocorrência não será excluída!' , 1, 0, .F. )
    _lRet := .F.

 Else

    //Valida se o pedido ainda existe
    SC5->(DBSetOrder(1))
    If SC5->(DBSeek(_aCabcPVEx[1][2]+_aCabcPVEx[2][2]))

       Help( ,, 'Atenção',, 'Não foi possível excluir pedido de descarte, ocorrência não será excluída!' , 1, 0, .F. )
       _lRet := .F.

    Else

       _oModelGrid:LoadValue('ZF5_PEDDEV',Space(6))
       _cpeddev := Space(6)
       _lRet := .T.

    EndIf

 EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS003J
Autor-------------: Josué Danich Prestes
Data da Criacao---: 02/04/2019
Descrição---------: Envia workflow de solicitação de cancelamento de cobrança
Parametros--------: _cNotaFiscal - numero da nota de saída da ocorrência
                    _cserie      - série da nota de saída da ocorrência
                    _lvalidado - se já fi pré validada a ocorrência
                    _cMotiCanc - Motivo do cancelamento
                    _cMotcus   - Motivo do Custo
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS003J(_cNotaFiscal,_cserie, _lvalidado,_lAuto, _cMotiCanc ,_cMotcus )

 Local _cEmail := SuperGetMV("IT_OCORAV1",.T.,"")
 Local _cAnexo := " "
 Local oAssunto
 Local _cAssunto := "Solicitação de cancelamento de cobrança da nota fiscal " + _cNotaFiscal + "/" + _cSerie + " da filial " + cfilant
 Local oButCan
 Local oButEnv
 Local oCc
 Local oGetAssun
 Local oGetCc
 Local oGetPara
 Local oMens
 Local oPara
 Local _cSetor := ""
 Local cMailCom := " "
 Local _aConfig	:= U_ITCFGEML('')
 Local _cEmlLog	:= ""
 Local cHtml    := ""
 Local nOpcA    := 2

 Local cGetAnx	:= _cAnexo
 Local cGetAssun:= _cAssunto + Space(150)
 Local cGetCc	:= Space(200)
 Local cGetMens	:= ""
 Local cGetPara	:= _cEmail + Space(150)
 Local _aAreSM0:= SM0->(FwGetArea()) As Array
 Local _cSuperv
 Local _cEmailsup
 Local _oModel       := FwModelActivete()
 Local _oModelMaster := _oModel:GetModel("ZF5MASTER") 
 Local _cNrPedV      := AllTrim(_oModelMaster:GetValue("ZF5_PEDIDO"))

 Default _lvalidado := .F.
 Default _lAuto     := .F.
 Default _cMotiCanc := " "
 Default _cMotcus   := " "

 Private oDlgMail

  If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
     cGetPara:= AllTrim(UsrRetMail(__cUserId))+Space(99)
 EndIf

 //Valida se ocorrência pode emitir aviso de devolução
 //Se status está encerrando, valida se já existe nota de débito
 If !_lAuto
   If ! _lvalidado

      If ! Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_STATUS") == "E"
         U_ITMsg("Ocorrência não está encerrada!","Atenção",,1)
         Return
      EndIf

      If ! U_ITMsg("Envia e-mail de cancelamento de cobrança para nota " + _cNotaFiscal + " com ocorrência de devolução?","Atenção",'Item ' + AllTrim(ZF5->ZF5_CODIGO),2,2,2)
         U_ITMsg("Envio de e-mail cancelado.","Atenção",,1)
         Return
      EndIf

      _cMotiCanc := ZF5->ZF5_TIPOO + "-" + AllTrim(ZF5->ZF5_MOTIVO)
      _cMotcus   := AllTrim(ZF5->ZF5_MOTCUS)

   EndIf
 EndIf

//==========================================  
// Obtem E-mail do supervisor
//==========================================
_cSuperv   := Posicione('SC5',1,xFilial("SC5")+_cNrPedV,'C5_VEND4')
_cEmailsup := ""

If ! Empty(_cSuperv)
   _cEmailsup := AllTrim(Posicione("SA3",1,xfilial("SA3")+_cSuperv,"A3_EMAIL") )
   If ! Empty(_cEmailsup)
      cGetPara := AllTrim(cGetPara) + ";" + _cEmailsup
   EndIf 
EndIf 

 _cTel  :=""
 PswOrder(1)
 PSWSEEK(__cUserId , .T. )
 If (Len(PswRet()) # 0) // Quando nao For rotina automatica do configurador
     _cSetor:= AllTrim(PswRet()[1][12])		// Pega departamento do usuario
 EndIf

 If Empty(_cSetor)
      _cSetor := "Logistica"
 EndIf
 If Empty(_cTel)
    _cTel:=AllTrim( Posicione('SM0',1,"01"+cFilant,'M0_TEL') )
 EndIf

 cHtml := 'À departamento de contas a receber,'
 cHtml += '<br><br>'
 cHtml += '&nbsp;&nbsp;&nbsp;Solicito cancelamento da cobrança dos títulos referentes à nota fiscal - ' + _cNotaFiscal + "/"  + _cserie + ' de nossa filial '+ cfilant +' devido à ocorrência de frete de devolução.<br>'
 cHtml += '&nbsp;&nbsp;&nbsp;Favor confirmar o recebimento, retornando com o seu CIENTE!'
 cHtml += '<br><br>'
 cHtml += 'Ocorrência: ' + AllTrim(_cMotiCanc)
 If !Empty(M->ZF5_MOTCUS)
    cHtml += '<br>'
    cHtml += 'Motivo do Custo: ' + AllTrim(M->ZF5_MOTCUS)
 EndIf
 cHtml += '<br><br>'
 cHtml += '<br><br>'
 cHtml += '&nbsp;&nbsp;&nbsp;A disposição!'
 cHtml += '<br><br>'
 cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
 cHtml += '<tr>'
 cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">'
 cHtml +=         '<p class=MsoNormal align=center style="text-align:center">'
 cHtml +=             '<b><span style="font-size:18.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">'+ Capital( AllTrim( UsrFullName( __cUserId ) ) ) +'</span></b>'
 cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
 cHtml +=     '</td>'
 cHtml +=     '<td style="background:#A2CFF0;padding:.75pt .75pt .75pt .75pt">&nbsp;</td>'
 cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">
 cHtml +=         '<table class=MsoNormalTable border=0 cellpadding=0>'
 cHtml +=              '<tr>'
 cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">'
 cHtml +=                      '<p class=MsoNormal><b><span style="font-size:13.5pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#6FB4E3;mso-fareast-language:PT-BR">' + _cSetor + '</span></b>'
 cHtml +=                      '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></b>
 cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"><br></span>
 cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
 cHtml +=                  '</td>'
 cHtml +=              '</tr>'
 cHtml +=              '<tr>'
 cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">
 cHtml +=                      '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Tel: ' + _cTel + '</span>'
 cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
 cHtml +=                  '</td>'
 cHtml +=              '</tr>'
 cHtml +=         '</table>'
 cHtml +=     '</td>'
 cHtml += '</tr>'
 cHtml += '</table>'
 cHtml += '<table class=MsoNormalTable border=0 cellpadding=0 width=437 style="width:327.75pt">'
 cHtml +=     '<tr>'
 cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
 cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
 cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR">'
 cHtml +=                 '<img width=400 height=51 src="http://www.italac.com.br/assinatura-italac/images/marcas-goiasminas-industria-de-laticinios-ltda.jpg">'
 cHtml +=             '</span>
 cHtml +=             '</p>'
 cHtml +=         '</td>'
 cHtml +=     '</tr>'
 cHtml += '</table>'
 cHtml += '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';display:none;mso-fareast-language:PT-BR">&nbsp;</span></p>'
 cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
 cHtml +=     '<tr>'
 cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
 cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
 cHtml +=             '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Política de Privacidade </span></b>'
 cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
 cHtml +=             '<p class=MsoNormal style="mso-margin-top-alt:auto;mso-margin-bottom-alt:auto;text-align:justify">'
 cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">
 cHtml +=                 'Esta mensagem é destinada exclusivamente para fins profissionais, para a(s) pessoa(s) a quem For dirigida, podendo conter informação confidencial e legalmente privilegiada. '
 cHtml +=                 'Ao recebê-la, se você não For destinatário desta mensagem, fica automaticamente notificado de abster-se a divulgar, copiar, distribuir, examinar ou, de qualquer forma, utilizar '
 cHtml +=                 'sua informação, por configurar ato ilegal. Caso você tenha recebido esta mensagem indevidamente, solicitamos que nos retorne este e-mail, promovendo, concomitantemente sua '
 cHtml +=                 'eliminação de sua base de dados, registros ou qualquer outro sistema de controle. Fica desprovida de eficácia e validade a mensagem que contiver vínculos obrigacionais, expedida '
 cHtml +=                 'por quem não detenha poderes de representação, bem como não esteja legalmente habilitado para utilizar o referido endereço eletrônico, configurando falta grave conforme nossa '
 cHtml +=                 'política de privacidade corporativa. As informações nela contidas são de propriedade da Italac, podendo ser divulgadas apenas a quem de direito e devidamente reconhecido pela empresa.'
 cHtml += '<BR>Ambiente: ['+ GETENVSERVER() +'] / Fonte: [AOMS003] </BR>'
 cHtml +=             '</span>'
 cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>'
 cHtml +=         '</td>'
 cHtml +=     '</tr>
 cHtml += '</table>'

 If !_lAuto
   DEFINE MSDIALOG oDlgMail TITLE "E-Mail" FROM 000, 000  TO 415, 584  PIXEL

      @ 005, 006 Say oPara PROMPT "Para:" SIZE 015, 007 OF oDlgMail  PIXEL
      @ 005, 030 MSGET oGetPara VAR cGetPara SIZE 256, 010 OF oDlgMail PICTURE "@x"  PIXEL
      @ 021, 006 Say oCc PROMPT "Cc:" SIZE 015, 007 OF oDlgMail  PIXEL
      @ 021, 030 MSGET oGetCc VAR cGetCc SIZE 256, 010 OF oDlgMail PICTURE "@x"  PIXEL
      @ 037, 006 Say oAssunto PROMPT "Assunto:" SIZE 022, 007 OF oDlgMail  PIXEL
      @ 037, 030 MSGET oGetAssun VAR cGetAssun SIZE 256, 010 OF oDlgMail PICTURE "@x"  PIXEL
      @ 069, 006 Say oMens PROMPT "Mensagem:" SIZE 030, 007 OF oDlgMail  PIXEL
      _oFont		:= TFont():New( 'Courier new' ,, 12 , .F. )
      _oScrAux	:= TSimpleEditor():New( 080 , 006 , oDlgMail , 285 , 105 ,,,,, .T. )

      _oScrAux:Load( cHtml )

      @ 189, 201 BUTTON oButEnv PROMPT "&Enviar"	SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 1 , cHtml := _oScrAux:RetText() , oDlgMail:End() ) PIXEL
      @ 189, 245 BUTTON oButCan PROMPT "&Cancelar"	SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 2 , oDlgMail:End() ) PIXEL

   ACTIVATE MSDIALOG oDlgMail CENTERED
 Else
    nOpcA := 1
 EndIf

 If nOpcA == 1

     cGetMens := AOMS003TT(cGetMens)

     // Chama a função para envio do e-mail
     U_ITENVMAIL( Lower(AllTrim(UsrRetMail(__cUserId))), cGetPara, cGetCc, cMailCom, cGetAssun, cHtml, cGetAnx, _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog ) 

     U_ITMsg( _cEmlLog+CHR(10) +CHR(13)+"PARA: "+AllTrim(cGetPara)+CHR(10) +CHR(13)+"CC: "+AllTrim(cGetCc) , 'Término do processamento!' , ,3 )

    _lEnviou := .T.

 Else
     U_ITMsg( 'Envio de e-mail cancelado pelo usuário.' , 'Atenção!' , ,1 )

    _lEnviou := .F.

 EndIf
FwRestArea(_aAreSM0)

Return

/*
===============================================================================================================================
Programa----------:AOMS003TT
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 12/02/2018
Descrição---------: Função criada para fazer a quebra de linha na mensagem digitada pelo usuário
Parametros--------: ExpC1	- Texto da mensagem
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS003TT(cGetMens)

 Local aTexto	:= StrTokArr( cGetMens, chr(10)+chr(13) )
 Local cRet		:= ""
 Local nI		:= 0

 For nI := 1 To Len(aTexto)
     cRet += aTexto[nI] + "<br>"
 Next nI

Return(cRet)

/*
===============================================================================================================================
Programa----------: AOMS003N
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/09/2019
Descrição---------: Rotina de pos validação da linha de grid das ocorrencias de frete.
                    Chamado 29686. Validar a ocorrência de sinistro e a existência de titulos de débito.
Parametros--------: _oModel = Modelo de dados.
Retorno-----------: _lRet = .T. ou .F.
===============================================================================================================================
*/
User Function AOMS003N(_oModel, _nLinha, _cAcao, _cCampo)

 Local _lRet := .T.
 Local _cNotaFiscal
 Local _cSerie
 Local _clojat
 Local _cCodigo
 Local _oModelMaster  := _oModel:GetModel("ZF5MASTER")
 Local _nI, _nLinAtu
 Local _cCodSinist := AllTrim(SuperGetMV( 'IT_CODSINI',.T.,'000026'))
 Local _cUsersHab := SuperGetMV("IT_USPROTI",.F.,"") As Character

 Begin Sequence

    _cNotaFiscal:= _oModelMaster:GetValue("ZF5MASTER","ZF5_DOCOC")
    _cSerie     := _oModelMaster:GetValue("ZF5MASTER","ZF5_SEROC")
    _cLojat     := Posicione("SF2",1,xFilial("SF2")+_cNotaFiscal+_cSerie,"F2_I_LTRA")
    _nLinAtu    := _oModel:GetLine()
    _cCodigo    := AllTrim(Str(Val(_oModel:GetValue('ZF5_CODIGO'))))  // Código da ocorrência por nota

    If _oModel:IsInserted(_nLinAtu) .Or. _oModel:IsUpdated(_nLinAtu)
         ZFC->(DBSetOrder(1))
         If ZFC->(DBSeek(xFilial("ZFC")+_oModel:GetValue("ZF5_TIPOO")))
            If ZFC->ZFC_PROTIT == "S"
               If !(RetCodUsr() $ _cUsersHab) .And. _oModel:GetValue("ZF5_DPRORR") > 0
                  _lRet := .F.
                  Help( ,, 'Atenção',, 'Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Usuário não tem permissão para usar este tipo de Ocorrencia.', 1, 0, .F. )
                  Break
               Else
                  If _oModel:GetValue("ZF5_DPRORR") == 0
                      U_ITMsg('Ocorrência ' + StrZero(Val(_cCodigo),6) + ' - Atenção pois esta ocorrencia esta sendo incluída ou atualizada com dias de prorrogação igual a 0.',"Atenção",,3)
                  EndIf
               EndIf
            EndIf
         EndIf
    EndIf

    If ! AllTrim( _oModel:GetValue("ZF5_TIPOO")) $ _cCodSinist
       Break
    EndIf

    SE2->(DBSetOrder(1)) // E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA

    If _oModel:IsInserted(_nLinAtu) .Or. _oModel:IsUpdated(_nLinAtu)

       For _nI := 1 To _oModel:Length()
           _oModel:GoLine( _nI )
           _cCodigo := AllTrim(Str(Val(_oModel:GetValue('ZF5_CODIGO',_nI))))  // Código da ocorrência por nota
           _cChave  := _oModel:GetValue('ZF5_CHVNDT',_nI)  // Chave: SE2->E2_FILIAL+SE2->E2_PREFIXO+SE2->E2_NUM+SE2->E2_PARCELA
           _cFornece:= ""
           _cLoja   := ""
           If _oModel:GetValue('ZF5_TIPOC')  == "T"
              _cFornece := AllTrim(_oModel:GetValue("ZF5_TRANSP"))
              _cLoja    := _oModel:GetValue("ZF5_LJTRAN")
           ElseIf _oModel:GetValue('ZF5_TIPOC')  == "3"
              _cFornece := _oModel:GetValue("ZF5_FORTER")
              _cLoja    := _oModel:GetValue("ZF5_LOJTER")
           EndIf

           If !Empty(_cChave)
              If Len(AllTrim(_cChave)) = Len(SE2->E2_FILIAL+SE2->E2_PREFIXO+SE2->E2_NUM)//CHAVE SEM PARCELA
                 _cSeekSE2:=_cChave + "01" + "NDF"+_cFornece+_cLoja//A chave e o cfilant já estam com a filai certa
              Else//CHAVE COM PARCELA - NOVO
                 _cSeekSE2:=_cChave + "NDF"+_cFornece+_cLoja//A chave e o cfilant já estam com a filai certa
              EndIf
              _cMostra:=_cSeekSE2
           Else//CHAVE ANTIGA
              _cSeekSE2:=xFilial("SE2")+"NDT"+SubStr(_cNotaFiscal,2,8) + _cCodigo + "01" + "NDF"
           EndIf

           If SE2->(DBSeek(_cSeekSE2))
              If Empty(_cChave)
                 _cMostra:=_cSeekSE2+SE2->E2_FORNECE+SE2->E2_LOJA
              EndIf
              U_ITMsg("Já existe uma nota de débito com a Chave: " + _cMostra + ", lançada para este mesmo tipo de ocorrencia.","Atenção",,1)
              Break
           EndIf

       Next _nI

    EndIf

 End Sequence

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS003O
Autor-------------: Julio de Paula Paz
Data da Criacao---: 21/09/2021
Descrição---------: Complementar a gravação de dados.
Parametros--------: _oModel = Modelo de dados.
Retorno-----------: _lRet = .T.
===============================================================================================================================
*/
User Function AOMS003O(_oModel)

 Local _oModelMaster := _oModel:GetModel("ZF5MASTER") As Object
 Local _oModelGrid   := _oModel:GetModel("ZF5DETAIL") As Object
 Local _nOperation   := _oModel:GetOperation() As Numeric
 Local _cNotaFiscal  As Character
 Local _cSerie       As Character
 Local _cMercEntreg  As Character
 Local _cSitEntreg   As Character
 Local _nRegAtu      As Numeric
 Local _nI           As Numeric

 Begin Transaction

    FWFormCommit(_oModel)//Grava o que esta no model

    _cNotaFiscal := _oModelMaster:GetValue("ZF5_DOCOC")
    _cSerie      := _oModelMaster:GetValue("ZF5_SEROC")
    _nLinhas     := _oModel:GetModel('ZF5DETAIL'):Length()
    _nRegAtu     := ZF5->(Recno())

    If _nOperation == MODEL_OPERATION_UPDATE
       _nRegAtu := ZF5->(Recno())
       _cMercEntreg := _oModelMaster:GetValue("ZF5_MERENT")
       _cSitEntreg  := _oModelMaster:GetValue("ZF5_SITENT")

       ZF5->(DBSetOrder(1)) // 1 => ZF5_FILIAL+ZF5_DOCOC+ZF5_SEROC
       ZF5->(MsSeek(xFilial("ZF5")+_cNotaFiscal+_cSerie))
       While ! ZF5->(Eof()) .And. ZF5->(ZF5_FILIAL+ZF5_DOCOC+ZF5_SEROC) == xFilial("ZF5")+_cNotaFiscal+_cSerie
          ZF5->(RecLock("ZF5",.F.))
          ZF5->ZF5_MERENT := _cMercEntreg
          ZF5->ZF5_SITENT := _cSitEntreg
          ZF5->(MSUnLock())
          ZF5->(DBSkip())
       EndDo

       ZF5->(DBGoTo(_nRegAtu))

    EndIf

    If _nOperation == MODEL_OPERATION_INSERT .Or. _nOperation == MODEL_OPERATION_UPDATE

        For _nI := 1 to _nLinhas
          _oModel:GetModel('ZF5DETAIL'):GoLine( _nI )

            ZFC->(DBSetOrder(1))
            If ZFC->(DBSeek(xFilial("ZFC")+_oModelGrid:GetValue("ZF5_TIPOO")))
                If _oModelGrid:GetValue("ZF5_DPRORR") > 0
                    ZFC->(DBSetOrder(1))
                    If ZFC->(DBSeek(xFilial("ZFC")+_oModelGrid:GetValue("ZF5_TIPOO")))
                        If ZFC->ZFC_PROTIT == "S" 
                            ZM4->(DBSetOrder(1))
                            If !(ZM4->(DBSeek(xFilial("ZM4")+_cNotaFiscal+_cSerie+"NF "+_oModelGrid:GetValue("ZF5_CODIGO"))))
                                If !_oModelGrid:IsDeleted() .And. _oModelGrid:IsUpdated()
                                    ZM4->(RecLock("ZM4",.T.))
                                    ZM4->ZM4_FILIAL := xFilial("ZM4")
                                    ZM4->ZM4_DOC    := _cNotaFiscal
                                    ZM4->ZM4_SERIE  := _cSerie
                                    ZM4->ZM4_TIPO   := "NF"
                                    ZM4->ZM4_CODIGO := _oModelGrid:GetValue("ZF5_CODIGO")
                                    ZM4->ZM4_DTSOL  := Date()
                                    ZM4->ZM4_SOLICI := __cUserId
                                    ZM4->ZM4_STATUS := "N"
                                    ZM4->(MSUnLock())
                                EndIf
                            Else
                                If _oModelGrid:IsDeleted()
                                    ZM4->(RecLock("ZM4",.F.))
                                    ZM4->(DbDelete())
                                    ZM4->(MSUnLock())
                                EndIf
                            EndIf
                        EndIf
                    EndIf
                EndIf
            EndIf
        Next _nI
        _aREcZF5:={}
        ZF5->(DBSetOrder(1))
        If ZF5->(DBSeek(SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE))
            While ZF5->(!Eof()) .And. SF2->F2_FILIAL == ZF5->ZF5_FILIAL;
                                   .And. SF2->F2_DOC    == ZF5->ZF5_DOCOC;
                                   .And. SF2->F2_SERIE  == ZF5->ZF5_SEROC
                aAdd(_aREcZF5,ZF5->(RECNO()) )
                ZF5->(DBSkip())
            EndDo
        EndIf
        U_AOMS3DTSF2("AOMS003",_aREcZF5,_oModel)//FUNÇÃO CHAMADA NO AOMS072 e AOMS074 e M460FIM
    EndIf

 End Transaction

 If _lEmail
    _cMensagem:=""
    _nTipo:=2
    For _nI := 1 TO Len(_aDadosEmailCom)
        U_AOMS3Comercial(_aDadosEmailCom[_nI])
    Next _nI
    U_ITMsg(_cMensagem,"Envio do E-MAIL",,_nTipo)
    _lEmail := .F.
 EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: ReplDatasTransTime
Autor-------------: Alex Wallauer
Data da Criacao---: 25/05/2023
Descrição---------: Atualiza todas as data de previstas e entregas na 05 da 42 e na 20 (carregamento) da troca nota
Parametros--------: _nRecnoSF2Atual = Recno do SF2 posicionado 
                    lTestarNF = .T. - Atualiza as datas na 42 da 05 tb e na #20 da 20 tb
Retorno-----------: .F. ou .T.
===============================================================================================================================
*/
User Function ReplDatasTransTime( _nRecnoSF2Atual , lTestarNF)//CHAMADA DA AOMS074.PRW TAMBEM

 Local _lRet:=.F. , T
 Local _aOrd:= SaveOrd({"SC5","SF2"}) // Salva a ordem dos indices.

 Local _cOperTriangular:= AllTrim(SuperGetMV("IT_OPERTRI",.T.,"05,42"))// Tipos de operações da operação trigular
 Local _cOperRemessa   := RIGHT(_cOperTriangular,2)//42

 Local _xF2_DTRC := SF2->F2_I_DTRC  // Entrega no Cliente (Dt.Canhoto)
 Local _xF2_PENOL:= SF2->F2_I_PENOL // Previsão de entrega no operador logístico
 Local _xF2_PENCL:= SF2->F2_I_PENCL // Previsão de entrega no cliente
 Local _xF2_DCHOL:= SF2->F2_I_DCHOL // Data de chegada no operador logístico
 Local _xF2_DCHCL:= SF2->F2_I_DCHCL // Data de chegada no cliente
 Local _xF2_DENCL:= SF2->F2_I_DENCL // Data de entrega no cliente **
 Local _xF2_DENOL:= SF2->F2_I_DENOL // Data de entrega no operador logístico  EDI  **
 Local _xF2_PENCO:= SF2->F2_I_PENCO // Previsão de entrega no cliente (original)
 Local _xF2_OUSER:= SF2->F2_I_OUSER // Usuario Informou o Op.Log
 Local _xF2_ODATA:= SF2->F2_I_ODATA // Data inf.
 Local _xF2_OHORA:= SF2->F2_I_OHORA // Hora Inf.
 Local _xF2_CUSER:= SF2->F2_I_CUSER // Usuário de aprovação do canhoto.
 Local _xF2_CDATA:= SF2->F2_I_CDATA // Data de digitação do Canhoto.
 Local _xF2_CHORA:= SF2->F2_I_CHORA // hora de digitação do Canhoto.
 Local _xF2_CORIG:= SF2->F2_I_CORIG // Origem
 Local _xF2_TT1TR:= SF2->F2_I_TT1TR // Transit Time 1o Trecho
 Local _xF2_TT2TR:= SF2->F2_I_TT2TR // Transit Time 2o Trecho
 Local _xF2_REDP := SF2->F2_I_REDP  // Transportadora de redespacho
 Local _xF2_RELO := SF2->F2_I_RELO  // Loja Transportadora de redespacho
 Local _xF2_OPER := SF2->F2_I_OPER  // Operador Logistico
 Local _xF2_OPLO := SF2->F2_I_OPLO  // Loja do Operador Logistico
 Local _xF2_OLRDT:= SF2->F2_I_OLRDT // Data do redirecionamento para operador logístico
 Local _xF2_OLRCD:= SF2->F2_I_OLRCD // Código do operador logístico do redirecionamento
 Local _xF2_OLRLJ:= SF2->F2_I_OLRLJ // Loja do operador logístico do redirecionamento
 Local _cOBSC    := ""

 Local aRecsSF2    := {}
 Local _nRegrTriFat:= 0
 Local _nRegrTransf:= 0
 Local _nRegSF2    := 0
 Local _nRegCopia  := 0

 SC5->(DBSetOrder(1))
 If SC5->(DBSeek(SF2->F2_FILIAL+AllTrim(SF2->F2_I_PEDID)))
    SF2->(DBSetOrder(1)) //F2_FILIAL+F2_DOC+F2_SERIE
    
    //CONTROLE DA TRIANGULAR
    If SC5->C5_I_OPER = _cOperRemessa//42 ***** REMESSA ******
       If SC5->(DBSeek(SC5->C5_FILIAL+SC5->C5_I_PVFAT))// POSICIONA NO PV DE FATURAMENTO (05)
          _cOBSC:= "CANHOTO CONF NA NOTA DE REMESSA "+SF2->F2_FILIAL + "/" + SF2->F2_DOC//Pega o numero da nota antes de desposicionar
          If SF2->(DBSeek(SC5->C5_FILIAL+SC5->C5_NOTA+SC5->C5_SERIE))
             _nRegrTriFat:= SF2->(RECNO()) //GUARDA A POSIÇÃO DA SF2 NA NOTA NO PV DE FATURAMENTO (05)
             _nRegCopia  := _nRegrTriFat
          EndIf
       EndIf
    ElseIf lTestarNF // 05 ***** FATURAMENTO *****
       If SC5->(DBSeek(SC5->C5_FILIAL+SC5->C5_I_PVREM))// POSICIONA NO PV DE REMESSA (42)
          If SF2->(DBSeek(SC5->C5_FILIAL+SC5->C5_NOTA+SC5->C5_SERIE))
             _cOBSC:= "CANHOTO CONF NA NOTA DE REMESSA "+SF2->F2_FILIAL + "/" + SF2->F2_DOC//Pega o numero da nota depois de posicionar
             _nRegrTriFat:= SF2->(RECNO()) //GUARDA A POSIÇÃO DA SF2 NA NOTA NO PV DE REMESSA (42)
             _nRegCopia  := _nRegrTriFat
          EndIf
       EndIf
    EndIf

    // CONTROLE DA TROCA NOTA
    If SC5->C5_I_TRCNF == "S" .And. SC5->C5_NUM == SC5->C5_I_PDFT .And. SC5->C5_I_OPER <> "20"// É PEDIDO DE FATURAMENTO (# 20), ATUALIZA O CARREGAMENTO (20)
       If SC5->(DBSeek(SC5->C5_I_FLFNC+SC5->C5_I_PDPR))
          _cOBSC:= "CANHOTO CONF NA NOTA DE FATURAMENTO "+SF2->F2_FILIAL + "/" + SF2->F2_DOC  // Pega o numero da nota antes de desposicionar
          If SF2->(DBSeek(SC5->C5_I_FLFNC+SC5->C5_NOTA+SC5->C5_SERIE))
            _nRegrTransf:= SF2->(RECNO()) // GUARDA A POSIÇÃO DA SF2 DA NOTA DE PV DE CARREGAMENTO
          EndIf
       EndIf
    ElseIf lTestarNF .And. SC5->C5_I_TRCNF == "S" .And. SC5->C5_NUM == SC5->C5_I_PDPR // É PEDIDO DE CARREGAMENTO (20) , ATUALIZA O FATURAMENTO (# 20)
       If SC5->(DBSeek(SC5->C5_I_FLFNC+SC5->C5_I_PDFT))
          If SF2->(DBSeek(SC5->C5_I_FLFNC+SC5->C5_NOTA+SC5->C5_SERIE))
             _cOBSC:= "CANHOTO CONF NA NOTA DE FATURAMENTO "+SF2->F2_FILIAL + "/" + SF2->F2_DOC//Pega o numero da nota depois de posicionar
             _nRegrTransf:= SF2->(RECNO()) //  GUARDA A POSIÇÃO DA SF2 DA NOTA DE PV DE FATURAMENTO
          EndIf
       EndIf
    EndIf
    aRecsSF2:={_nRegrTriFat,_nRegrTransf}
 EndIf

 For T := 1 TO Len(aRecsSF2)
     _nRegSF2:=aRecsSF2[T]

     If _nRegSF2 > 0

        SF2->(DBGoTo(_nRegSF2))
        SF2->(RecLock("SF2",.F.))

        SF2->F2_I_DTRC  := _xF2_DTRC  // Entrega no Cliente (Dt.Canhoto)
        SF2->F2_I_PENOL := _xF2_PENOL // Previsão de entrega no operador logístico
        SF2->F2_I_PENCL := _xF2_PENCL // Previsão de entrega no cliente
        SF2->F2_I_DCHOL := _xF2_DCHOL // Data de chegada no operador logístico
        SF2->F2_I_DCHCL := _xF2_DCHCL // Data de chegada no cliente
        SF2->F2_I_DENCL := _xF2_DENCL // Data de entrega no cliente
        SF2->F2_I_DENOL := _xF2_DENOL // Data de entrega no operador logístico  EDI // pode ser editado.
        SF2->F2_I_PENCO := _xF2_PENCO // Previsão de entrega no cliente (original)
        SF2->F2_I_OUSER := _xF2_OUSER // Usuario Informou o Op.Log
        SF2->F2_I_ODATA := _xF2_ODATA // Data inf.
        SF2->F2_I_OHORA := _xF2_OHORA // Hora Inf.
        SF2->F2_I_CUSER := _xF2_CUSER // Usuário de aprovação do canhoto.
        SF2->F2_I_CDATA := _xF2_CDATA // Data de digitação do Canhoto.
        SF2->F2_I_CHORA := _xF2_CHORA // hora de digitação do Canhoto.
        SF2->F2_I_CORIG := _xF2_CORIG // Origem
        SF2->F2_I_TT1TR := _xF2_TT1TR // Transit Time 1o Trecho
        SF2->F2_I_TT2TR := _xF2_TT2TR // Transit Time 2o Trecho
        SF2->F2_I_OBRC  := _cOBSC     // Observacao
        SF2->F2_I_OLRDT := _xF2_OLRDT // Data do redirecionamento para operador logístico
        SF2->F2_I_OLRCD := _xF2_OLRCD // Código do operador logístico do redirecionamento
        SF2->F2_I_OLRLJ := _xF2_OLRLJ // Loja do operador logístico do redirecionamento
        If _nRegCopia = _nRegSF2
           SF2->F2_I_REDP  := _xF2_REDP  // Transportadora de redespacho
           SF2->F2_I_RELO  := _xF2_RELO  // Loja Transportadora de redespacho
           SF2->F2_I_OPER  := _xF2_OPER  // Operador Logistico
           SF2->F2_I_OPLO  := _xF2_OPLO  // Loja do Operador Logistico
        EndIf
        SF2->(MSUnLock())
        _lRet:=.T.
     EndIf
 Next T

 RestOrd(_aOrd)
 SF2->(DBGoTo(_nRecnoSF2Atual))

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS03MP
Autor-------------: Julio de Paula Paz
Data da Criacao---: 21/09/2021
Descrição---------: Pré-Validação do Modelo de Dados.
Parametros--------: _oModel = Modelo de dados.
Retorno-----------: _lRet = .T.
===============================================================================================================================
*/
User Function AOMS03MP(_oModel)
 
 Local _lRet := .T.
 Local _nI
 Local _nOperation   := _oModel:GetOperation()
 Local _oModelMaster := _oModel:GetModel("ZF5MASTER")
 Local _oModelGrid   := _oModel:GetModel("ZF5DETAIL")

 Begin Sequence

    If _nOperation == MODEL_OPERATION_INSERT .Or. _nOperation == MODEL_OPERATION_UPDATE
       // ZF5MASTER
       _cNrNf    := _oModelMaster:GetValue('ZF5_DOCOC')
       _cSerieNf := _oModelMaster:GetValue('ZF5_SEROC')

       If Empty(_aItOcorre) .Or. (! Empty(_aItOcorre) .And. _aItOcorre[1,1] <> _cNrNf)
          _aItOcorre := {}
          For _nI := 1 To _oModelGrid:Length()
              _oModelGrid:GoLine(_nI)
              _cCodigo := _oModelGrid:GetValue('ZF5_CODIGO')

              aAdd(_aItOcorre,{_cNrNf,_cSerieNf,_cCodigo, xFilial("ZF5"),_nI})
          Next _nI
       EndIf
    EndIf

 End Sequence

Return _lRet


/*
===============================================================================================================================
Programa----------: AOMS3Comercial
Autor-------------: Alex Wallauer
Data da Criacao---: 14/12/2023
Descrição---------: Monta e envia email para o comercial
Parametros--------: _aDadosOcorrencia = _aDadosEmailCom[E] as Static
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AOMS3Comercial(_aDadosOcorrencia As Array) As Logical
 
 Local _aConfig       := U_ITCFGEML('') , E  As Numeric, _nI As Numeric
 Local _cEmlLog       := "" As Character
 Local _cMsgEml       := "" As Character
 Local cGetCc	       := "" As Character
 Local cGetPara	    := "" As Character
 Local _cNomeFil      := cFilant+" - "+AllTrim( Posicione('SM0',1,"01"+cFilant,'M0_FILIAL') ) As Character
 Local cTit           := "" As Character
 Local cGetAssun      := "" As Character
 Local _cOperTria     := AllTrim(SuperGetMV("IT_OPERTRI",.T.,"05,42")) As Character
 Local _cOperFat      := LEFT(_cOperTriangular,2) As Character //05
 Local _cOperRemessa  := RIGHT(_cOperTriangular,2) As Character //42
 Local _cZPG_EMAIL    := "" As Character
 Local _cRepresentante:= "" As Character
 Local _cCoordenador  := "" As Character
 Local _cFilsEnviaEm  := AllTrim(SuperGetMV( "IT_OCOPMAI",.T.,"")) As Character
 Local _cNomeSA2      := "" As Character
 Local _cOpCod        := "" As Character
 Local _cOPLoja       := "" As Character
 Local _cCliCarre     := "" As Character
 Local _cLojCarre     := "" As Character
 Local _cNomCarre     := "" As Character
 Local _NfCarre       := "" As Character
 Local _cCNPJCarre    := "" As Character
 Local _cEndCarre     := "" As Character
 Local _cBairroCarre  := "" As Character
 Local _cEmailsup     := "" As Character 

 If !Empty(_cFilsEnviaEm) .And. !cFilAnt $ _cFilsEnviaEm
    Return .F.
 EndIf

 M->ZF5_DTOCOR := _aDadosOcorrencia[01]
 M->ZF5_CODIGO := AllTrim(_aDadosOcorrencia[02])
 M->ZF5_MOTIVO := AllTrim(_aDadosOcorrencia[03])
 M->ZF5_MOTCUS := AllTrim(_aDadosOcorrencia[04])
 M->ZF5_TIPOO  := AllTrim(_aDadosOcorrencia[05])
 M->ZF5_TRANSP := AllTrim(_aDadosOcorrencia[06])
 M->ZF5_LJTRAN := AllTrim(_aDadosOcorrencia[07])
 M->ZF5_NTRANS := AllTrim(_aDadosOcorrencia[08])
 cTit          := "OCORRENCIA "+M->ZF5_MOTIVO
 cGetAssun     := cTit+" - Filial: "+_cNomeFil+" - Nfe: "+M->ZF5_DOCOC+" - Data Ocorrência: "+DToC(M->ZF5_DTOCOR)+ " - Sequencia "+M->ZF5_CODIGO

 SF2->(DBSetOrder(1))
 SF2->(DBSeek(xFilial("SF2")+M->ZF5_DOCOC+AllTrim(M->ZF5_SEROC)))
 SC5->(DBSetOrder(1))
 SC5->(DBSeek(SF2->(F2_FILIAL+F2_I_PEDIDO)))

 If !Empty(SC5->C5_VEND1)
    _cRepresentante:=AllTrim(Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_EMAIL") )
 EndIf
 If !Empty(SC5->C5_VEND2)
    _cCoordenador:=AllTrim(Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND2,"A3_EMAIL"))
 EndIf
 If !Empty(SC5->C5_ASSCOD)
    _cZPG_EMAIL:=AllTrim(Posicione("ZPG",1,xFilial("ZPG")+SC5->C5_ASSCOD,"ZPG_EMAIL"))
 EndIf

 _acTo:={}
 If !Empty(_cZPG_EMAIL)
    aAdd(_acTo,Lower(_cZPG_EMAIL))
 EndIf
 If !Empty(_cCoordenador)
    aAdd(_acTo,Lower(_cCoordenador))
 EndIf
 If !Empty(_cRepresentante) .And. aScan(_acTo,Lower(_cRepresentante)) = 0
    aAdd(_acTo,Lower(_cRepresentante))
 EndIf
 If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
     _acTo:={}
 EndIf
 If !Empty(__cUserId)
    cGetCc  := LOWER(AllTrim(UsrRetMail(__cUserId))) // Pega e-mail do usuario
    aAdd(_acTo,cGetCc)
 EndIf

 //==========================================  
 // Obtem E-mail do supervisor para envio.
 //==========================================
 _cEmailsup := ""

 If ! Empty(SC5->C5_VEND4)
    _cEmailsup := AllTrim(Posicione("SA3",1,xfilial("SA3")+SC5->C5_VEND4,"A3_EMAIL") )
    If ! Empty(_cEmailsup)
       _cEmailsup := Lower(_cEmailsup)
       aAdd(_acTo,_cEmailsup)
    EndIf 
 EndIf 
  
 If Len(_acTo) = 0
    Return .F.
 EndIf

 _cTipoEntrega:=U_TipoEntrega(SC5->C5_I_AGEND)

 _aTLinhas:={}
 aAdd(_aTLinhas,{"Motivo Ocorrência  ",M->ZF5_TIPOO+" - "+M->ZF5_MOTIVO })
 aAdd(_aTLinhas,{"Data Ocorrência    ",DToC(M->ZF5_DTOCOR) }) //M->ZF5_DTOCOR
 aAdd(_aTLinhas,{"Nota fiscal        ",M->ZF5_DOCOC   }) //M->ZF5_DOCOC
 aAdd(_aTLinhas,{"Serie NF           ",M->ZF5_SEROC   }) //M->ZF5_SEROC
 aAdd(_aTLinhas,{"Data Emissao NF    ",DToC(SF2->F2_EMISSAO)}) //SF2->F2_EMISSAO
 aAdd(_aTLinhas,{"Natureza operação  ",Posicione("ZB4",1,xFilial("ZB4")+SC5->C5_I_OPER, "ZB4_DESCRI")}) //Posicione("ZB4",1,xFilial("ZB4")+SC5->C5_I_OPER, "ZB4_DESCRI"))
 aAdd(_aTLinhas,{"Ordem de carga     ",M->ZF5_CARGA   }) //M->ZF5_CARGA
 aAdd(_aTLinhas,{"Cliente            ",M->ZF5_NCLIEN  }) //M->ZF5_NCLIEN;
 aAdd(_aTLinhas,{"Representante      ",AllTrim(M->ZF5_NREPRE)}) //M->ZF5_NREPRE
 aAdd(_aTLinhas,{"Coordenador        ",M->ZF5_NCOOR   }) //M->ZF5_NCOOR
 aAdd(_aTLinhas,{"Assistente         ",SC5->C5_ASSNOM  })// 
 aAdd(_aTLinhas,{"Pedido             ",AllTrim(M->ZF5_PEDIDO)}) //M->ZF5_PEDIDO
 aAdd(_aTLinhas,{"Volume NF          ",AllTrim(M->ZF5_VOLUM)}) //M->ZF5_VOLUM
 aAdd(_aTLinhas,{"Peso NF            ",TRANS(M->ZF5_PESON,'@E 9,999,999,999,999.9999')   }) //M->ZF5_PESON
 aAdd(_aTLinhas,{"Tipo carregamento  ",If(SC5->C5_I_TPVEN="F","Carga Fechada","Carga Fracionada")}) //SC5->C5_I_TPVEN // NOME;
 aAdd(_aTLinhas,{"Tipo de Entrega    ",_cTipoEntrega  }) //SC5->C5_I_AGEND // MOSTRAR NOME;
 aAdd(_aTLinhas,{"Tipo da carga      ",IIf(SC5->C5_I_TIPCA="1","Paletizada",If(SC5->C5_I_TIPCA="2","Batida",""))}) //SC5->C5_I_TIPCA // MOSTRAR NOME;
 aAdd(_aTLinhas,{"Data de agendamento",DToC(SC5->C5_I_DTENT)  }) //SC5->C5_I_DTENT //
 aAdd(_aTLinhas,{"Transportadora     ",AllTrim(M->ZF5_TRANSP)+" "+AllTrim(M->ZF5_LJTRAN)+" - "+AllTrim(M->ZF5_NTRANS) })//TRANSPORTADOR E LOJA FORAM PARA AS OCORRENCIAS (GRID)
 If !Empty(SF2->F2_I_REDP)
    _cOpCod  := SF2->F2_I_REDP
    _cOPLoja := SF2->F2_I_RELO
 ElseIf !Empty(SF2->F2_I_OPER)
    _cOpCod  := SF2->F2_I_OPER
    _cOpLoja := SF2->F2_I_OPLO
 EndIf
 If !Empty(_cOpCod) .And. !Empty(_cOPLoja) .And. SA2->(MSSEEK(xFilial("SA2")+_cOpCod+_cOPLoja))
    _cNomeSA2:=LEFT(SA2->A2_NOME,Len(ZF5->ZF5_NOMTER))
 EndIf
 aAdd(_aTLinhas,{"Operador Logistico "  ,_cNomeSA2})
 aAdd(_aTLinhas,{"Código da ocorrencia ",AllTrim(M->ZF5_CODIGO) })
 aAdd(_aTLinhas,{"Motivo custo       "  ,AllTrim(M->ZF5_MOTCUS) })

 _cProdutos:=""
 SC6->(DBSetOrder(1))
 If SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
    While SC5->C5_NUM == SC6->C6_NUM .And. SC5->C5_FILIAL == SC6->C6_FILIAL .And. SC5->(!Eof())
       _cProdutos+=AllTrim(Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_DESC"))+'<br>'
       SC6->(DBSkip())
    EndDo
 EndIf

 _cCliCarre     := SC5->C5_CLIENT
 _cLojCarre     := SC5->C5_LOJACLI

 If SC5->C5_I_TRCNF = 'S'
    _cFilFatur := SC5->C5_I_FILFT
    _cPedFatur := SC5->C5_I_PDFT
    _cFilcarre := SC5->C5_I_FLFNC
    _cPedCarre := SC5->C5_I_PDPR
    If SC5->C5_I_PDFT == SC5->C5_NUM //ESTOU NO DE Faturamento
       _cCliCarre := Posicione("SC5",1,SC5->C5_I_FLFNC+SC5->C5_I_PDPR,"C5_CLIENTE")
       _cLojCarre := SC5->C5_LOJACLI
       _NfCarre   := SC5->C5_NOTA
       _cNomCarre := Posicione("SA1",1,xFilial("SA1")+_cCliCarre+_cLojCarre,"A1_NOME")
    ElseIf SC5->C5_I_PDPR = SC5->C5_NUM //ESTOU NO DE Carregamento
       _cCliCarre := Posicione("SC5",1,SC5->C5_I_FILFT+SC5->C5_I_PDFT,"C5_CLIENTE")
       _cLojCarre := SC5->C5_LOJACLI
        _NfCarre  := SC5->C5_NOTA
       _cNomCarre := Posicione("SA1",1,xFilial("SA1")+_cCliCarre+_cLojCarre,"A1_NOME")
    EndIf
 ElseIf SC5->C5_I_OPER $ _cOperTria // Tipos de operações da operação trigular
    If SC5->C5_I_OPER = _cOperFat // Oper 05-Vendas
       _cCliCarre := Posicione("SC5",1,SC5->C5_FILIAL+SC5->C5_I_PVREM,"C5_CLIENTE")
       _cLojCarre := SC5->C5_LOJACLI
       _NfCarre   := SC5->C5_NOTA
       _cNomCarre := Posicione("SA1",1,xFilial("SA1")+_cCliCarre+_cLojCarre,"A1_NOME")
    ElseIf SC5->C5_I_OPER = _cOperRemessa // Oper 42-Remessa
       _cCliCarre := Posicione("SC5",1,SC5->C5_FILIAL+SC5->C5_I_PVFAT,"C5_CLIENTE")
       _cLojCarre := SC5->C5_LOJACLI
       _NfCarre   := SC5->C5_NOTA
       _cNomCarre := Posicione("SA1",1,xFilial("SA1")+_cCliCarre+_cLojCarre,"A1_NOME")
    EndIf
 EndIf

 _cNomCarre    := Posicione("SA1",1,xFilial("SA1")+_cCliCarre+_cLojCarre,"A1_NOME")
 _cCNPJCarre   := Posicione("SA1",1,xFilial("SA1")+_cCliCarre+_cLojCarre,"A1_CGC")
 _cEndCarre    := Posicione("SA1",1,xFilial("SA1")+_cCliCarre+_cLojCarre,"A1_END")
 _cBairroCarre := Posicione("SA1",1,xFilial("SA1")+_cCliCarre+_cLojCarre,"A1_BAIRRO")

 aAdd(_aTLinhas,{"NF Vinculada     ",_NfCarre })//Usar mesma logica existente no programa ROMS067, variável _NfCarre;
 aAdd(_aTLinhas,{"Cliente vinculado",_cCliCarre + "-" + _cLojCarre + " " + _cNomCarre })//Usar mesma logica existente no programa ROMS067, variável _cCliCarre;
 aAdd(_aTLinhas,{"CNPJ             ",_cCNPJCarre })
 aAdd(_aTLinhas,{"Endereço         ",_cEndCarre })
 aAdd(_aTLinhas,{"Bairro           ",_cBairroCarre })
 aAdd(_aTLinhas,{"Município          ",M->ZF5_CIDADE  }) //M->ZF5_CIDADE
 aAdd(_aTLinhas,{"Estado             ",M->ZF5_UF      }) //M->ZF5_UF
 aAdd(_aTLinhas,{"Produtos"         ,_cProdutos })//Buscar todos os produto do pedido (ZF5_PEDIDO) buscando na tabela SC6,trazer nome do produto;

 _cMsgEml := '<html>'
 _cMsgEml += '<head><title>'+cTit+'</title></head>'
 _cMsgEml += '<body>'
 _cMsgEml += '<style Type="text/css"><!--'
 _cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
 _cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
 _cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
 _cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'//#E5E5E5
 _cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
 _cMsgEml += '--></style>'
 _cMsgEml += '<center>'
 _cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
 _cMsgEml += '<table class="bordasimples" width="600">'
 _cMsgEml += '    <tr>'
 _cMsgEml += '	     <td class="titulos"><center><b>'+cTit+'</b></center></td>'
 _cMsgEml += '	 </tr>'
 _cMsgEml += '</table>'
 _cMsgEml += '<br>'
 _cMsgEml += '<table class="bordasimples" width="600">'
 _cMsgEml += '    <tr>'
 _cMsgEml += '      <td align="center" colspan="2" class="grupos"><b>OCORRENCIA</b></td>'
 _cMsgEml += '    </tr>'
 _cMsgEml += '    <tr>'
 _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Incluida por: </b></td>'
 _cMsgEml += '      <td class="itens" >'+ UsrFullName(__cUserId) +'</td>'
 _cMsgEml += '    </tr>'
 _cMsgEml += '    <tr>'
 _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Filial:</b></td>'
 _cMsgEml += '      <td class="itens" >'+ _cNomeFil +'</td>'
 _cMsgEml += '    </tr>'
 If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
    _cMsgEml += ' <tr>'
    _cMsgEml += '   <td class="itens" align="center" width="30%"><b>Emails Oficial</b></td>'
    _cMsgEml += '   <td class="itens" >'+ _cZPG_EMAIL+"<br>"+_cCoordenador+"<br>"+_cRepresentante +'</td>'
    _cMsgEml += ' </tr>'
 EndIf
 _cMsgEml += '</table>'

 //          01   02   03   04   05
 _aSizeOK:={"20","80"}

 _cMsgEml += '<br>'
 _cMsgEml += '<table class="bordasimples" width="1300">'
 _cMsgEml += '    <tr>'
 _cMsgEml += '      <td align="center" colspan="'+AllTrim(Str(Len(_aSizeOK)))+'" class="grupos"><b>DADOS DA OCORENCIA</b></td>'
 _cMsgEml += '    </tr>'
 _cMsgEml += '    #LISTAOK#'
 _cMsgEml += '</table>'
 _cMsgEml += '<br>'

 _cOKLista:=""
 For _nI := 1 TO Len(_aTLinhas)
     _cOKLista += '    <tr>'
     _cOKLista += "      <td width='"+_aSizeOK[01]+"' BGCOLOR=#E5E5E5 ><font color= #000000 style='font-size: 15px; font-weight: bold;'>"+_aTLinhas[_nI][01]+"</font></td>
     _cOKLista += '      <td class="itens" align="left" width="'+_aSizeOK[02]+'%">'+ _aTLinhas[_nI][02]+'</td>'
     _cOKLista += '    </tr>'
 Next _nI

 _cMsgEml:=StrTran(_cMsgEml,"#LISTAOK#",_cOKLista)

 _cMsgEml += '</center>'
 _cMsgEml += '</body>'
 _cMsgEml += '</html>'

 //RODAPE FIXO
 _cTel:=""
 If (Len(PswRet()) # 0) // Quando nao For rotina automatica do configurador
     _cSetor:= AllTrim(PswRet()[1][12])		// Pega departamento do usuario
 EndIf
 If Empty(_cSetor)
      _cSetor := "Logistica"
 EndIf
 If Empty(_cTel)
    _cTel:=AllTrim( Posicione('SM0',1,"01"+cFilant,'M0_TEL') )
 EndIf

 _cMsgEml += '<br><br>'
 _cMsgEml += '<br><br>'
 _cMsgEml += '&nbsp;&nbsp;&nbsp;A disposição!'
 _cMsgEml += '<br><br>'
 _cMsgEml += '<table class=MsoNormalTable border=0 cellpadding=0>'
 _cMsgEml += '<tr>'
 _cMsgEml +=     '<td style="padding:.75pt .75pt .75pt .75pt">'
 _cMsgEml +=         '<p class=MsoNormal align=center style="text-align:center">'
 _cMsgEml +=             '<b><span style="font-size:18.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">'+ Capital( AllTrim( UsrFullName( __cUserId ) ) ) +'</span></b>'
 _cMsgEml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
 _cMsgEml +=     '</td>'
 _cMsgEml +=     '<td style="background:#A2CFF0;padding:.75pt .75pt .75pt .75pt">&nbsp;</td>'
 _cMsgEml +=     '<td style="padding:.75pt .75pt .75pt .75pt">
 _cMsgEml +=         '<table class=MsoNormalTable border=0 cellpadding=0>'
 _cMsgEml +=              '<tr>'
 _cMsgEml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">'
 _cMsgEml +=                      '<p class=MsoNormal><b><span style="font-size:13.5pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#6FB4E3;mso-fareast-language:PT-BR">' + _cSetor + '</span></b>'
 _cMsgEml +=                      '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></b>
 _cMsgEml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"><br></span>
 _cMsgEml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
 _cMsgEml +=                  '</td>'
 _cMsgEml +=              '</tr>'
 _cMsgEml +=              '<tr>'
 _cMsgEml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">
 _cMsgEml +=                      '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Tel: '+_cTel+'</span>'
 _cMsgEml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
 _cMsgEml +=                  '</td>'
 _cMsgEml +=              '</tr>'
 _cMsgEml +=         '</table>'
 _cMsgEml +=     '</td>'
 _cMsgEml += '</tr>'
 _cMsgEml += '</table>'
 _cMsgEml += '<table class=MsoNormalTable border=0 cellpadding=0 width=437 style="width:327.75pt">'
 _cMsgEml +=     '<tr>'
 _cMsgEml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
 _cMsgEml +=             '<p class=MsoNormal align=center style="text-align:center">'
 _cMsgEml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR">'
 _cMsgEml +=                 '<img width=400 height=51 src="http://www.italac.com.br/assinatura-italac/images/marcas-goiasminas-industria-de-laticinios-ltda.jpg">'
 _cMsgEml +=             '</span>
 _cMsgEml +=             '</p>'
 _cMsgEml +=         '</td>'
 _cMsgEml +=     '</tr>'
 _cMsgEml += '</table>'
 _cMsgEml += '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';display:none;mso-fareast-language:PT-BR">&nbsp;</span></p>'
 _cMsgEml += '<table class=MsoNormalTable border=0 cellpadding=0>'
 _cMsgEml +=     '<tr>'
 _cMsgEml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
 _cMsgEml +=             '<p class=MsoNormal align=center style="text-align:center">'
 _cMsgEml +=             '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Política de Privacidade </span></b>'
 _cMsgEml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
 _cMsgEml +=             '<p class=MsoNormal style="mso-margin-top-alt:auto;mso-margin-bottom-alt:auto;text-align:justify">'
 _cMsgEml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">
 _cMsgEml +=                 'Esta mensagem é destinada exclusivamente para fins profissionais, para a(s) pessoa(s) a quem For dirigida, podendo conter informação confidencial e legalmente privilegiada. '
 _cMsgEml +=                 'Ao recebê-la, se você não For destinatário desta mensagem, fica automaticamente notificado de abster-se a divulgar, copiar, distribuir, examinar ou, de qualquer forma, utilizar '
 _cMsgEml +=                 'sua informação, por configurar ato ilegal. Caso você tenha recebido esta mensagem indevidamente, solicitamos que nos retorne este e-mail, promovendo, concomitantemente sua '
 _cMsgEml +=                 'eliminação de sua base de dados, registros ou qualquer outro sistema de controle. Fica desprovida de eficácia e validade a mensagem que contiver vínculos obrigacionais, expedida '
 _cMsgEml +=                 'por quem não detenha poderes de representação, bem como não esteja legalmente habilitado para utilizar o referido endereço eletrônico, configurando falta grave conforme nossa '
 _cMsgEml +=                 'política de privacidade corporativa. As informações nela contidas são de propriedade da Italac, podendo ser divulgadas apenas a quem de direito e devidamente reconhecido pela empresa.'
 _cMsgEml += '<BR>Ambiente: ['+ GETENVSERVER() +'] / Fonte: [AOMS003] </BR>'
 _cMsgEml +=             '</span>'
 _cMsgEml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>'
 _cMsgEml +=         '</td>'
 _cMsgEml +=     '</tr>
 _cMsgEml += '</table>'

  _lOK:=.F.
 _lErro:=.F.
 For E := 1 TO Len(_acTo)

     cGetPara:=_acTo[E]
     U_ITENVMAIL(_aConfig[01], cGetPara,         ,         ,cGetAssun,_cMsgEml ,          ,_aConfig[01],_aConfig[02],_aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog ) 

     _cMensagem+="Ocor.: "+AllTrim(M->ZF5_CODIGO)+"-"+_cEmlLog+" Para: "+cGetPara + CRLF
     If "SUCESSO" $ Upper(_cEmlLog)
        _lOK:=.T.
     Else
        _lErro:=.T.
     EndIf
 Next E
 _nTipo:=2 // V
 If _lOK .And. _lErro
    _nTipo:=3 // !
 ElseIf !_lOK .And. _lErro
    _nTipo:=1 // X
 EndIf
 
Return .T.

/*
===============================================================================================================================
Programa----------: AOMS003M
Autor-------------: Alex Wallauer
Data da Criacao---: 26/12/2023
Descrição---------: Pontos de entradas do AOMS103
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS003M()
 
 Local aParam := ParamIXB

 If aParam <> NIL
    //oObj    := aParam[1]
    cIdPonto  := aParam[2]
    //cIdModel:= aParam[3]
    //lIsGrid := (Len(aParam) > 3)

    If     cIdPonto == "MODELPOS" //"Chamada na validação total do modelo."
    ElseIf cIdPonto == "FORMPOS" //"Chamada na validação total do formulário."
     ElseIf cIdPonto == "FORMLINEPRE"//Chamada na pré validação da linha do formulário
     ElseIf cIdPonto == "FORMLINEPOS"//Chamada na validação da linha do formulário
     ElseIf cIdPonto == "MODELCOMMITTTS"//Chamada após a gravação total do modelo e dentro da transação.
     ElseIf cIdPonto == "MODELCOMMITNTTS"//Chamada após a gravação total do modelo e fora da transação.
     ElseIf cIdPonto == "FORMCOMMITTTSPRE"//Chamada após a gravação da tabela do formulário.
     ElseIf cIdPonto == "FORMCOMMITTTSPOS"//Chamada após a gravação da tabela do formulário.
     ElseIf cIdPonto == "MODELCANCEL"
     ElseIf cIdPonto == "BUTTONBAR"
            aRet := {}
            aAdd( aRet ,{"Atualizar Telefones" , 'Atualiza Tels.' , {|| U_AOMS3Atu(.F.) } , "Atualizar Telefones" } )
           aAdd( aRet ,{"Verifica Carga" , 'Verifica Carga' , {|| U_VISCARGA( ZF5->ZF5_FILIAL, ZF5->ZF5_CARGA ) } , "Atualizar Telefones" } )
           Return aRet
    EndIf

 EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS3Atu
Autor-------------: Alex Wallauer
Data da Criacao---: 26/12/2023
Descrição---------: Atualiza os campos de nome + telefone
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS3Atu(_lGravar)
 
 Local _oModel := FWModelActive()
 Local _oModelMaster

 If _lGravar .Or. _oModel:GetOperation() = 4

    M->ZF5_DMOTOR:=U_AOMS003Z("ZF5_DMOTOR")
    M->ZF5_NREPRE:=U_AOMS003Z("ZF5_NREPRE")
    M->ZF5_NCOOR :=U_AOMS003Z("ZF5_NCOOR" )
    M->ZF5_NCLIEN:=U_AOMS003Z("ZF5_NCLIEN")
    If _lGravar
       ZF5->ZF5_DMOTOR        :=M->ZF5_DMOTOR
       ZF5->ZF5_NREPRE        :=M->ZF5_NREPRE
       ZF5->ZF5_NCOOR         :=M->ZF5_NCOOR
       ZF5->ZF5_NCLIEN        :=M->ZF5_NCLIEN
       (cAliasAux)->STATUS2   :="N"//Algum Diferente? NÃO
       (cAliasAux)->MARCA     :=" "
       (cAliasAux)->ZF5_DMOTOR:=M->ZF5_DMOTOR
       (cAliasAux)->ZF5_NREPRE:=M->ZF5_NREPRE
       (cAliasAux)->ZF5_NCOOR :=M->ZF5_NCOOR
       (cAliasAux)->ZF5_NCLIEN:=M->ZF5_NCLIEN
    Else
       _oModelMaster:=_oModel:GetModel("ZF5MASTER")
       _oModelMaster:LoadValue("ZF5_DMOTOR",M->ZF5_DMOTOR)
       _oModelMaster:LoadValue("ZF5_NREPRE",M->ZF5_NREPRE)
       _oModelMaster:LoadValue("ZF5_NCOOR" ,M->ZF5_NCOOR )
       _oModelMaster:LoadValue("ZF5_NCLIEN",M->ZF5_NCLIEN)
    EndIf

 EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: CalcTransiTime  #CalcTransiTime ()
Autor-------------: Alex Wallauer
Data da Criacao---: 01/02/2024
Descrição---------: Calcula Transit time da Unidade de Carregamento até o Operador Logístico e
                    Calcula Transit time do Endereço do Operador Logístico até o Cliente
Parametros--------: _dDataMRef - Data para somar o DIAS de Transit time - SAIDA ITALAC
                    _dDtnoOL   - Data para somar o DIAS de Transit time - SAIDA OPERADOR LOGISTICO
Retorno-----------: {DIAS Transit time da Unidade de Carregamento até o Operador Logístico,
                     DIAS Transit time do Endereço do Operador Logístico até o Cliente,
                     Dias do TRECHO 1,
                     Dias do TRECHO 2}
===============================================================================================================================
*/
User Function CalcTransiTime(_dDataMRef,_dDtnoOL)
 
 Local lBuscaItalacCliente:=.F.// DESTINO DA ITALAC PARA O CLIENTE
 Local cCodOL      := ""
 Local cLojaOP     := ""
 Local cCodCli     := ""
 Local cLojaCli    := ""
 Local _cFilCarreg := ""
 Local _cEstado    := ""
 Local _dDataPENCO := CTOD("")
 Local _dDataPENOL := CTOD("")
 DEFAULT _dDtnoOL  := CTOD("")
 DEFAULT _dDataMRef:= _dDtnoOL
 SF2->(DBSetOrder(1))
 SC5->(DBSetOrder(1))
 SC5->(DBSeek(SF2->F2_FILIAL+SF2->F2_I_PEDID))

 cCodCli    := SF2->F2_CLIENTE
 cLojaCli   := SF2->F2_LOJA
 _cFilCarreg:= SC5->C5_FILIAL

 If SC5->C5_I_TRCNF == "S"
    If !Empty(SC5->C5_I_FLFNC) //SE PEDIDO DE FATURAMENTO
        _cFilCarreg := SC5->C5_I_FLFNC
    EndIf

    If SC5->C5_I_FLFNC == SC5->C5_FILIAL //SE PEDIDO DE CARREGAMENTO
       If  SC5->(DBSeek(SC5->C5_I_FILFT+SC5->C5_I_PDFT))// SEEK no PEDIDO de FATURAMENTO
           cCodCli := SC5->C5_CLIENTE
           cLojaCli:= SC5->C5_LOJACLI
       EndIf
    EndIf
 EndIf

 SA1->(DBSetOrder(1))
 SA1->(DBSeek(xFilial("SA1") + cCodCli + cLojaCli))
 _cEstado    := SA1->A1_EST
 _cCodMunic  := SA1->A1_COD_MUN
 _nDiasZ31   := 0//TRECHO 1 - Preenche na função BuscaZ31() - M460FIM.PRW
 _nDiasZG5   := 0//TRECHO 2 - Preenche na função BuscaZG5() - M460FIM.PRW
lBuscaItalacCliente:=.F.// DESTINO DA ITALAC PARA O CLIENTE
 
 DAI->(DBSetOrder(3))
 If DAI->(DBSeek(SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE))//SE TEM CARGA

     If !Empty(DAI->DAI_I_OPLO)
        cCodOL :=DAI->DAI_I_OPLO
        cLojaOP:=DAI->DAI_I_LOPL
     Else
        cCodOL :=DAI->DAI_I_TRED
        cLojaOP:=DAI->DAI_I_LTRE
     EndIf

     If !Empty(cCodOL)

        If Empty(_dDtnoOL)
           //SE ALTERAR A LOGICA AQUI ALTERAR Na #GrvTransiTime() no M460FIM.PRW  TAMBEM
 
           // DESTINO: DA ITALAC PARA OPERADOR LOGISTICO
           SA2->(DBSetOrder(1))
           SA2->(DBSeek(xFilial("SA2") + cCodOL + cLojaOP))
           _cEstadoOP := SA2->A2_EST
           _cCodMunOP := SA2->A2_COD_MUN
                    //_cFilCarreg,_cCod ,_cLoja ,_cOperPedV    ,_cTipoVenda    ,_cEstado,_cCodMunic,@_dDataRef,@_nDiasZG5,_cLocalEmb
           U_BuscaZG5(_cFilCarreg,cCodOL,cLojaOP,SC5->C5_I_OPER,SC5->C5_I_TPVEN,_cEstadoOP,_cCodMunOP,@_dDataMRef,@_nDiasZG5,SC5->C5_I_LOCEM)// DESTINO: DA ITALAC PARA OPERADOR LOGISTICO
           If Empty(_dDataMRef)
              _dDataMRef:=SF2->F2_EMISSAO
           EndIf
           _dDataPENOL:= U_IT_DTVALIDA(_dDataMRef,,.T.)//Se a data calculada da entrega cair em um domingo ou em um feriado nacional, a data deve ser o próximo dia útil.
           _dDataMRef := _dDataPENOL
        Else
           _dDataPENOL:= _dDtnoOL
        EndIf
        // DESTINO: DO OPERADOR LOGISTICO PARA O CLIENTE
        If !Empty(_dDataPENOL)
           _dDataMRef := _dDataPENOL
                    //cCodOL,cLojaOP,cCodCli,cLojaCli,_dDataRef//A data não via como referencia (@) pq vai ser calculada depois apenas com dias Uteis
           U_BuscaZ31(cCodOL,cLojaOP,cCodCli,cLojaCli,_dDataMRef,@_nDiasZ31)//DESTINO: DO OPERADOR LOGISTICO PARA O CLIENTE
           _dDataPENCO:= U_IT_DTVALIDA(_dDataMRef,_nDiasZ31)//SE A DATA CALCULADA DA ENTREGA DEVE CONTAR SÓ DIA UTIL
           _dDiasCorridos:=_dDataMRef+_nDiasZ31//#DIAS CORRIDOS
        EndIf
     Else// SE NAO TEM OPERADOR LOGISTICO
        lBuscaItalacCliente:=.T.// DESTINO DA ITALAC PARA O CLIENTE
     EndIf

 Else//SE NAO TEM CARGA
     lBuscaItalacCliente:=.T.// DESTINO DA ITALAC PARA O CLIENTE
 EndIf

 //SE ALTERAR A LOGICA AQUI ALTERAR Na #GrvTransiTime() no M460FIM.PRW  TAMBEM
 // DESTINO: DA ITALAC PARA O CLIENTE
 _nPesoTot:= SF2->F2_PBRUTO//FORA DO If PQ PRECISO dessa variavel fora do If tambem
 If lBuscaItalacCliente

    If !Empty(SC5->C5_I_AGRUP)
       _cQuery:=" SELECT SUM(C5_I_PESBR) C5_I_PESBR FROM "+ RETSQLNAME("SC5") + " WHERE C5_FILIAL = '"+ xFilial('SC5')+"' AND D_E_L_E_T_ = ' ' "
       _cQuery+=" AND C5_I_AGRUP = '"+SC5->C5_I_AGRUP+"' "
       _cAliasGru:= GetNextAlias()
       MPSysOpenQuery( _cQuery , _cAliasGru)
       If (_cAliasGru)->C5_I_PESBR > 0
          _nPesoTot:= (_cAliasGru)->C5_I_PESBR //Soma o peso dos pedidos agrupado
       EndIf
       (_cAliasGru)->(DBCloseArea())
    
    ElseIf !Empty(SC5->C5_I_PEVIN)
       _aSalvaAreaSC5:=SC5->(FwGetArea())//Salva recno e ordem
       _cPedVinc:=SC5->C5_I_PEVIN
       SC5->(DBSetOrder(14))      // C5_NUM+C5_TIPO+C5_I_BLCRE
       If SC5->(DBSeek(_cPedVinc))// POSICIONA NO PEDIDO VINCULADO sem a filail pq pode estar em outra filial quando pediodos de troca NF
          _nPesoTot+=SC5->C5_I_PESBR//Soma o peso do pedido vinculado
       EndIf
       SC5->(FwRestArea(_aSalvaAreaSC5))
    EndIf

    _nDiasZG5 := 0
    _dDtMRefSalva:=_dDataMRef
    _nPesCarg := SuperGetMV("IT_PESFOUV",.F.,4000)
    
    If _nPesoTot < _nPesCarg // **** FRACIONADA **** Calcular * apenas dias úteis *
                //_cFilCarreg,_cCod  ,_cLoja  ,_cOperPedV   ,_cTipoVenda     ,_cEstado,_cCodMunic,_dDataRef //A data não via como referencia pq vai ser calculada depois
       U_BuscaZG5(_cFilCarreg,cCodCli,cLojaCli,SC5->C5_I_OPER,SC5->C5_I_TPVEN,_cEstado,_cCodMunic,_dDataMRef,@_nDiasZG5,SC5->C5_I_LOCEM)// DESTINO: DA ITALAC PARA O CLIENTE
       _dDiasCorridos:=_dDtMRefSalva+_nDiasZG5 //#DIAS CORRIDOS
       If Empty(_dDataMRef)
          _dDataMRef:=SF2->F2_EMISSAO
       EndIf
       _dDataPENCO:= U_IT_DTVALIDA(_dDataMRef,_nDiasZG5)//Data calculada da entrega deve contar só dia util: não conta sabado, domingo e feriado nacional
    
    Else// **** FECHADA **** Calcular * dias corridos *
                //_cFilCarreg,_cCod  ,_cLoja  ,_cOperPedV    ,_cTipoVenda    ,_cEstado,_cCodMunic,@_dDataRef
       U_BuscaZG5(_cFilCarreg,cCodCli,cLojaCli,SC5->C5_I_OPER,SC5->C5_I_TPVEN,_cEstado,_cCodMunic,@_dDataMRef,@_nDiasZG5,SC5->C5_I_LOCEM)// DESTINO: DA ITALAC PARA O CLIENTE
       _dDiasCorridos:=_dDtMRefSalva+_nDiasZG5 //#DIAS CORRIDOS
       If Empty(_dDataMRef)
          _dDataMRef:=SF2->F2_EMISSAO
       EndIf
       _dDataPENCO:= U_IT_DTVALIDA(_dDataMRef)//Se a data calculada da entrega cair em um sabado, domingo e feriado nacional, a data deve ser o próximo dia útil.       
    EndIf

 EndIf
 If SC5->C5_I_DTENT >= _dDiasCorridos .And. (SC5->C5_I_AGEND == "M" .Or. SC5->C5_I_AGEND == "A")
    _dDataPENCO := SC5->C5_I_DTENT // Previsão de entrega no cliente
 EndIf

 aRet:={_dDataPENOL,;// SF2->F2_I_PENOL - Previsão de entrega no operador logístico
        _dDataPENCO,;// SF2->F2_I_PENCL - Previsão de entrega no cliente
        _nDiasZG5  ,;// SF2->F2_I_TT1TR - Dias do TRECHO 1
        _nDiasZ31   }// SF2->F2_I_TT2TR - Dias do TRECHO 2

Return aRet

/*
===============================================================================================================================
Programa----------: AOMS03OPR
Autor-------------: Antonio Neves
Data da Criacao---: 20/03/2024
Descrição---------: Retorna o Operador Logístico
Parametros--------: __nOpc, __cFilial, __cDocOc, __cSerOc
Retorno-----------: _cInfOper
===============================================================================================================================
*/
User Function AOMS03OPR(__nOpc, __cFilial, __cDocOc, __cSerOc)

    Local _cInfOper   := ""
    Local _cCodOper   := ""
    Local _cLojOper   := ""

    If __nOpc == 1
        _cInfOper   := Posicione("SF2",1,__cFilial+__cDocOc+__cSerOc,"F2_I_OPER")
    ElseIf __nOpc == 2
        _cInfOper   := Posicione("SF2",1,__cFilial+__cDocOc+__cSerOc,"F2_I_OPLO")
    ElseIf __nOpc == 3
        _cCodOper   := Posicione("SF2",1,__cFilial+__cDocOc+__cSerOc,"F2_I_OPER")
        _cLojOper   := SF2->F2_I_OPLO
        _cInfOper   := Posicione("SA2",1,xFilial("SA4")+_cCodOper+_cLojOper,"A2_CGC")
    ElseIf __nOpc == 4
        _cCodOper   := Posicione("SF2",1,__cFilial+__cDocOc+__cSerOc,"F2_I_OPER")
        _cLojOper   := SF2->F2_I_OPLO
        _cInfOper   := Posicione("SA2",1,xFilial("SA2")+_cCodOper+_cLojOper,"A2_NOME")
    ElseIf __nOpc == 5
        _cCodOper   := Posicione("SF2",1,__cFilial+__cDocOc+__cSerOc,"F2_I_OPER")
        _cLojOper   := SF2->F2_I_OPLO
        _cInfOper   := Posicione("SA2",1,xFilial("SA2")+_cCodOper+_cLojOper,"A2_EST")
    ElseIf __nOpc == 6
        _cCodOper   := Posicione("SF2",1,__cFilial+__cDocOc+__cSerOc,"F2_I_OPER")
        _cLojOper   := SF2->F2_I_OPLO
        _cInfOper   := Posicione("SA2",1,xFilial("SA2")+_cCodOper+_cLojOper,"A2_MUN")
    ElseIf __nOpc == 7
        _cCodOper   := Posicione("SF2",1,__cFilial+__cDocOc+__cSerOc,"F2_I_OPER")
        _cLojOper   := SF2->F2_I_OPLO
        _cInfOper   := Posicione("SA2",1,xFilial("SA2")+_cCodOper+_cLojOper,"A2_DDD")
    ElseIf __nOpc == 8
        _cCodOper   := Posicione("SF2",1,__cFilial+__cDocOc+__cSerOc,"F2_I_OPER")
        _cLojOper   := SF2->F2_I_OPLO
        _cInfOper   := Posicione("SA2",1,xFilial("SA2")+_cCodOper+_cLojOper,"A2_TEL")
    EndIf


Return _cInfOper

/*
===============================================================================================================================
Programa----------: VISCARGA
Autor-------------: Antonio Neves
Data da Criacao---: 21/03/2024
Descrição---------: Retorno Da Relação de Carga
Parametros--------: _cFilial = Código da Filial
                    _cCarga  = Numero da Carga
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function VISCARGA(_cFilial, _cCarga)

  Local _aItCarga  := {}
  Local _cNomeCli  := {}
  Local _aItens    := {}
  Local _nPesTot   := 0

  Begin Sequence

   SA1->(DBSetOrder(1))
   DAI->(DBSetOrder(1))

   If DAI->(MsSeek(_cFilial+U_ItKey(_cCarga,"DAI_COD")))
      While !DAI->(Eof()) .And. DAI->DAI_FILIAL == _cFilial .And. DAI->DAI_COD == U_ItKey(_cCarga,"DAI_COD")

         _cNomeCli := ""
         If SA1->(MsSeek(xFilial("SA1")+DAI->DAI_CLIENT+DAI->DAI_LOJA))
             _cNomeCli := SA1->A1_NOME
         EndIf

         _aItCarga := {}
         aAdd(_aItCarga, DAI->DAI_NFISCA)
         aAdd(_aItCarga, DAI->DAI_SERIE)
         aAdd(_aItCarga, DAI->DAI_CLIENT)
         aAdd(_aItCarga, DAI->DAI_LOJA)
         aAdd(_aItCarga, _cNomeCli)
         aAdd(_aItCarga, Transform(DAI->DAI_PESO,"@E 999,999,999.9999"))
         aAdd(_aItens, _aItCarga)

         _nPestot += DAI->DAI_PESO

         DAI->(DBSkip())
      EndDo
   EndIf

   If Len(_aItens) = 0
      U_ITMsg("Não existe Carga "+_cFilial+_cCarga,"Atenção",,1)
      Return .F.
   EndIf

   _cTitulo:= "Relação de Carga: " + AllTrim(_cCarga) + "  - Peso Total: " + Transform(_nPestot,"@E 999,999,999.9999")
   _aCabec := {"Nota Fiscal", "Serie","Cliente","Loja","Razão Social","Peso da Nota"}

   U_ITListBox(_cTitulo , _aCabec , _aItens , .T. , 1 , "Exportação excel/arquivo")

 End Sequence

Return

/*
===============================================================================================================================
Programa----------: AOMS3DTSF2
Autor-------------: Alex Wallauer
Data da Criacao---: 26/09/2024
Descrição---------: Rotina de gravacao de datas do SF2 do programaa: AOMS003 / AOMS072 / AOMS074 / M460FIM
Parametros--------: _cOrigem : programa AOMS003 / AOMS072 / AOMS074 / M460FIM / 
                    _aRecZF5 : array de recnos do ZF5 / 
                    _oModel  : NÃO USA MAIS POR ENQUANTO
                    _lTesteNF: SE .T. é pq chamou da funcao U_TestesNF do M460FIM
Retorno-----------: .T. ou .F.
===============================================================================================================================*/
User Function AOMS3DTSF2(_cOrigem As Character,_aRecZF5 As Array,_oModel As Object, _lTesteNF As Logical ) As Logical

 Local _nI           As Numeric
 Local _oModelMaster As Object
 Local _oModelGrid   As Object
 Local _dDtTipoA     As Date
 Local _dDtTipoB     As Date
 Local _dDtTipoC     As Date
 Local _dDtTipoD     As Date
 Local _dDtTipoE     As Date
 Local _dDtTipoF     As Date
 Local _dZF5DTOCOR   As Date
 Local _cTipoOcorr   As Character
 Local _cDtTran      As Character
 Local _cAliasZDS    As Character
 Local _cQuery       As Character
 Local _cObsCom      As Character
 Local _cStatusSit   As Character
 Local _cStatusEmi   As Character
 Local _cListaSF2    As Character
 Local _cAmbiente    As Character
 Local _cZF5CODIGO   As Character
 Local _cListaOco    As Character
 Local _lGravaSF2    As Logical
 Local _lOriGravado  As Logical
 Local _aRec_TA_TF   As Array
 DEFAULT _lTesteNF := .F.
 _dDtTipoA   := CTOD("")
 _dDtTipoB   := CTOD("")
 _dDtTipoC   := CTOD("")
 _dDtTipoD   := CTOD("")
 _dDtTipoE   := CTOD("")
 _dDtTipoF   := CTOD("")
 _dDtREOPL_S := CTOD("")
 _cDtTran    := ""
 _cAliasZDS  := ""
 _cQuery     := ""
 _cObsCom    := ""
 _cStatusSit := ""
 _cStatusEmi := ""
 _cListaSF2  :="TIPO(ZFC_DTTRAN);CAMPO;ANTES;DEPOIS"+CRLF
 _cAmbiente  := AllTrim(Upper(GETENVSERVER()))
 _lGravaSF2  := .T.
 _lOriGravado:= (_cOrigem = "AOMS003" .Or. _cOrigem = "AOMS072" .Or. _cOrigem = "AOMS074" .Or. _cOrigem = "M460FIM_GRAVA" .Or. _cOrigem = "M460FIM_LER")
 _aRec_TA_TF := {}

 If _cOrigem = "TELA"//NÃO ESTMAOS USANDO POR ENQUANTO

    _oModelMaster:= _oModel:GetModel("ZF5MASTER")
    _oModelGrid  := _oModel:GetModel("ZF5DETAIL")
    _nLinhas     := _oModelGrid:Length()
    _oModelGrid:GoLine( _nLinhas )
    _cStatusSit  := _oModelGrid:GetValue("ZF5_STUSIT")
    _cStatusEmi  := _oModelGrid:GetValue("ZF5_STUEMI")
    _cObsCom     := _oModelGrid:GetValue("ZF5_OBSCOM")
    _cNotaFiscal := _oModelMaster:GetValue("ZF5_DOCOC")
    _cSerie      := _oModelMaster:GetValue("ZF5_SEROC")
    _cZF5Filial  := xFilial("ZF5")

 ElseIf _lOriGravado

    _nLinhas    := Len(_aRecZF5)
    _aRecZF5    := aSort(_aRecZF5)//ORDENA POR RECNO
    
     ZF5->(DBGoTo(_aRecZF5[_nLinhas]))
    _cStatusSit := ZF5->ZF5_STUSIT
    _cStatusEmi := ZF5->ZF5_STUEMI
    _cObsCom    := ZF5->ZF5_OBSCOM
    _cNotaFiscal:= ZF5->ZF5_DOCOC
     _cPedido   := AllTrim(ZF5->ZF5_PEDIDO)
    _cSerie     := ZF5->ZF5_SEROC
    _cZF5Filial := ZF5->ZF5_FILIAL
    
    If _cOrigem = "M460FIM_LER"
       _lGravaSF2:= .F.
    EndIf
 Else
    Return .F.
 EndIf

 If _lGravaSF2
    SF2->(DBSeek(_cZF5Filial+_cNotaFiscal+_cSerie))
    SC5->(DBSeek(_cZF5Filial+_cPedido))
    For _nI := 1 to _nLinhas
        ZF5->(DBGoTo(_aRecZF5[_nI]))
        ZF5->(RecLock("ZF5",.F.))
        ZF5->ZF5_DTATUA := "N"
        ZF5->(MSUnLock())
    Next _nI
    
    _aRecZF5:= BuscaRecZF5(_cZF5Filial,_cNotaFiscal,_cSerie)//Busca só so recnos do ZF5 validos
    _nLinhas:= Len(_aRecZF5)
    
    _aDatas:= U_CalcTransiTime(SF2->F2_EMISSAO)
    
    SF2->(RecLock("SF2",.F.))
    SF2->F2_I_PENOL := _aDatas[1]// Previsão de entrega no operador logístico
    SF2->F2_I_PENCL := _aDatas[2]// Previsão de entrega no cliente
    SF2->F2_I_PENCO := _aDatas[2]// Previsão de entrega no cliente (original)
    SF2->F2_I_TT1TR := _aDatas[3]// Dias do TRECHO 1
    SF2->F2_I_TT2TR := _aDatas[4]// Dias do TRECHO 2
    SF2->F2_I_DCHOL := CTOD("")  // Data de chegada no operador logístico
    SF2->F2_I_DENOL := CTOD("")  // Data de entrega no operador logístico  EDI // pode ser editado.
    SF2->F2_I_DCHCL := CTOD("")  // Data de chegada no cliente
    SF2->F2_I_DENCL := CTOD("")  // Data de entrega no cliente
    SF2->F2_I_OLRDT := CTOD("")  // Data do redirecionamento para operador logístico
    SF2->F2_I_OLRCD := " "       // Código do operador logístico do redirecionamento
    SF2->F2_I_OLRLJ := " "       // Loja do operador logístico do redirecionamento

    SF2->(MSUnLock())
 
 EndIf

 _cListaOco:="ZF5_TIPOO;ZFC_DTTRAN;ZF5_DTOCOR;ZF5_CODIGO"+CRLF

 SF2->(DBSetOrder(1))
 SC5->(DBSetOrder(1))

 For _nI := 1 to _nLinhas

     If _cOrigem = "TELA"//não usa por enquanto

        _oModelGrid:GoLine( _nI )
        _cTipoOcorr :=_oModelGrid:GetValue("ZF5_TIPOO")
        _dZF5DTOCOR :=_oModelGrid:GetValue("ZF5_DTOCOR")
        _cZF5CODIGO :=_oModelGrid:GetValue("ZF5_CODIGO")
        _cPedido    :=AllTrim(_oModelMaster:GetValue('ZF5_PEDIDO'))
        _cEstonado  :=_oModelGrid:GetValue("ZF5_ESTONO")

     ElseIf _lOriGravado

        ZF5->(DBGoTo(_aRecZF5[_nI]))
        _cTipoOcorr :=ZF5->ZF5_TIPOO
        _dZF5DTOCOR :=ZF5->ZF5_DTOCOR
        _cZF5CODIGO :=ZF5->ZF5_CODIGO
        _cPedido    :=AllTrim(ZF5->ZF5_PEDIDO)
        _cEstonado  :=ZF5->ZF5_ESTONO
     EndIf

     SF2->(DBSeek(_cZF5Filial+_cNotaFiscal+_cSerie))
     SC5->(DBSeek(_cZF5Filial+_cPedido))

     _dF2EMISSAO  := SF2->F2_EMISSAO
     _lTemOperador:= (!Empty(SF2->F2_I_REDP) .Or. !Empty(SF2->F2_I_OPER))
     //_lPVAgendado := .T.// Retirado dia 09/04/25 - Alex / Vanderlei solicitou - (SC5->C5_I_AGEND == "M" .Or. SC5->C5_I_AGEND == "A")
     _cDtTran     := Posicione("ZFC",1,xFilial("ZFC")+_cTipoOcorr,"ZFC_DTTRAN") // 1 = ZFC_FILIAL+ZFC_CODIGO
     _cZFC_OLREDI  := ZFC->ZFC_OLREDI// "S" ou "N" - Redirecionamento de operador logístico
     _lTemData    := .F.
     _aRec_TA_TF  := {0,0}

     If _cEstonado = "S"//SE ESTORNADO NÃO LE O ZF5
        Loop
     EndIf

     If _cZFC_OLREDI = "S" .And. _dZF5DTOCOR >= _dF2EMISSAO .And. _dZF5DTOCOR <= Date() //Redirecionamento de operador logístico
        _dDtREOPL_S :=  _dZF5DTOCOR     // ZF5_DOCOR  - Data do redirecionamento para operador logístico
        _cZF5_OLRCOD:=  ZF5->ZF5_OLRCOD // ZF5_OLRCOD - Código do operador logístico do redirecionamento
        _cZF5_OLRLOJ:=  ZF5->ZF5_OLRLOJ // ZF5_OLRLOJ - Loja do operador logístico do redirecionamento
     EndIf

     If _cDtTran == "A"  .And. (_dZF5DTOCOR >= _dF2EMISSAO .And. _dZF5DTOCOR <= DATE())
        _dDtTipoA := _dZF5DTOCOR
        _cListaOco+= "'"+_cTipoOcorr+";["+_cDtTran+"];"+DToC(_dZF5DTOCOR)+";'"+_cZF5CODIGO+CRLF
        _lTemData:=.F.//Para por ZF5_DTATUA="N" em todos os Tipos "A" e por "S" só no For apos o final
        If _cOrigem = "TELA"//não usa por enquanto
           _aRec_TA_TF[1]:=_oModelGrid:GetLine()
        Else
           _aRec_TA_TF[1]:=ZF5->(RECNO())
        EndIf

     ElseIf _cDtTran == "B"  .And. (Empty(_dDtTipoB) .And. _dZF5DTOCOR >= _dF2EMISSAO .And. _dZF5DTOCOR <= Date() ) .And. _lTemOperador
        _dDtTipoB := _dZF5DTOCOR
        _cListaOco+= "'"+_cTipoOcorr+";["+_cDtTran+"];"+DToC(_dZF5DTOCOR)+";'"+_cZF5CODIGO+CRLF
        _lTemData:=.T.

     ElseIf _cDtTran == "C"  .And. (Empty(_dDtTipoC) .And. _dZF5DTOCOR >= _dF2EMISSAO .And. _dZF5DTOCOR <= Date() ) .And. _lTemOperador
        _dDtTipoC := _dZF5DTOCOR
        _cListaOco+= "'"+_cTipoOcorr+";["+_cDtTran+"];"+DToC(_dZF5DTOCOR)+";'"+_cZF5CODIGO+CRLF
        _lTemData:=.T.

     ElseIf _cDtTran = "D"  .And. (Empty(_dDtTipoD) .And. _dZF5DTOCOR >= _dF2EMISSAO .And. _dZF5DTOCOR <= Date() )
        _dDtTipoD := _dZF5DTOCOR
        _cListaOco+= "'"+_cTipoOcorr+";["+_cDtTran+"];"+DToC(_dZF5DTOCOR)+";'"+_cZF5CODIGO+CRLF
        _lTemData:=.T.

     ElseIf _cDtTran = "E"  .And. (Empty(_dDtTipoE) .And. _dZF5DTOCOR >= _dF2EMISSAO .And. _dZF5DTOCOR <= Date() )
        _dDtTipoE   := _dZF5DTOCOR
        _cListaOco+= "'"+_cTipoOcorr+";["+_cDtTran+"];"+DToC(_dZF5DTOCOR)+";'"+_cZF5CODIGO+CRLF
        _lTemData:=.T.

     ElseIf _cDtTran == "F"  .And. _dZF5DTOCOR >= _dF2EMISSAO //.AND. _lPVAgendado//Tipo F pode aceitar data maior que Date()
        _dDtTipoF := _dZF5DTOCOR
        _cListaOco+= _cTipoOcorr+";["+_cDtTran+"];"+DToC(_dZF5DTOCOR)+";'"+_cZF5CODIGO+CRLF
        _lTemData :=.F.//Para por ZF5_DTATUA="N" em todos os Tipos "F" e por "S" só no For apos o final
        If _cOrigem = "TELA"//não usa por enquanto
           _aRec_TA_TF[2]:=_oModelGrid:GetLine()
        Else
           _aRec_TA_TF[2]:=ZF5->(RECNO())
        EndIf
     EndIf

      If _lGravaSF2 .And. _cDtTran $ "A,B,C,D,E,F" 
        If _cOrigem = "TELA"//não usa por enquanto
           _oModelGrid:SetValue("ZF5_DTATUA", If(_lTemData,"S","N") )
        Else
           ZF5->(RecLock("ZF5",.F.))
           ZF5->ZF5_DTATUA := If(_lTemData,"S","N")
           ZF5->(MSUnLock())
        EndIf
      EndIf

 Next _nI

 If _lGravaSF2 
    For _nI := 1 to Len(_aRec_TA_TF)
        If _aRec_TA_TF[_nI] > 0
          If _cOrigem = "TELA"//não usa por enquanto
             _oModelGrid:GoLine(_aRec_TA_TF[_nI])
             _oModelGrid:SetValue("ZF5_DTATUA", "S" )
          Else
             ZF5->(DBGoTo(_aRec_TA_TF[_nI]))
             ZF5->(RecLock("ZF5",.F.))
             ZF5->ZF5_DTATUA := "S"
             ZF5->(MSUnLock())
          EndIf
        EndIf
    Next _nI
 EndIf

 If _lGravaSF2 .And. _cOrigem = "AOMS003" .And. (!Empty(AllTrim(_cStatusSit)) .Or.  !Empty(AllTrim(_cStatusEmi)) )

    _cQuery := "SELECT ZDS.R_E_C_N_O_ RECZDS "
    _cQuery += "FROM "+RetSqlName("ZDS") + " ZDS "
    _cQuery += "WHERE ZDS.D_E_L_E_T_ = ' ' "
    _cQuery += "AND ZDS_NFORIG LIKE '%"+_cNotaFiscal+" "+Rtrim(_cSerie)+"%' "
    _cQuery += "AND ZDS_FILIAL = '"+_cZF5Filial+"' "
    _cQuery := ChangeQuery(_cQuery)
    _cAliasZDS := GetNextAlias()

    MPSysOpenQuery( _cQuery , _cAliasZDS )

    (_cAliasZDS)->(DBGoTop())

    While  (_cAliasZDS)->(!Eof())
       ZDS->(DBGoTo((_cAliasZDS)->RECZDS))
       ZDS->(RecLock("ZDS",.F.))
       If !Empty(AllTrim(_cStatusSit))
          ZDS->ZDS_STUSIT := _cStatusSit
       EndIf
       If !Empty(AllTrim(_cStatusEmi))
          ZDS->ZDS_STUEMI := _cStatusEmi
       EndIf
       If !Empty(AllTrim(_cObsCom))
          ZDS->ZDS_OBSCOM := ZDS->ZDS_OBSCOM + CRLF + _cObsCom
       EndIf
       ZDS->(MSUnLock())
       (_cAliasZDS)->(DBSkip())
    EndDo
    (_cAliasZDS)->(DBCloseArea())
 EndIf

 If Empty(_dDtTipoA) .And. _nLinhas > 0
    _dDtTipoA:= _dF2EMISSAO
 EndIf

 If (!Empty(_dDtTipoA) .OR.;
     !Empty(_dDtTipoB) .OR.;
     !Empty(_dDtTipoC) .OR.;
     !Empty(_dDtTipoD) .OR.;
     !Empty(_dDtTipoE) .OR.;
     !Empty(_dDtTipoF) .OR.;
     !Empty(_dDtREOPL_S)) .And. _nLinhas > 0

    If _cOrigem = "TELA"//não usa por enquanto
       _cZF5DOCOC  := _oModelMaster:GetValue("ZF5_DOCOC")
       _cZF5SEROC  := _oModelMaster:GetValue("ZF5_SEROC")
       _cZF5CLIENT := _oModelMaster:GetValue("ZF5_CLIENT")
       _cZF5LOJA   := _oModelMaster:GetValue("ZF5_LOJA")
       _cPedido    := AllTrim(_oModelMaster:GetValue('ZF5_PEDIDO'))
    ElseIf _lOriGravado
       ZF5->(DBGoTo(_aRecZF5[_nLinhas]))
       _cZF5DOCOC  := ZF5->ZF5_DOCOC
       _cZF5SEROC  := ZF5->ZF5_SEROC
       _cZF5CLIENT := ZF5->ZF5_CLIENT
       _cZF5LOJA   := ZF5->ZF5_LOJA
       _cPedido    := AllTrim(ZF5->ZF5_PEDIDO)
    EndIf
    If _cOrigem = "M460FIM_LER"
       _dDtLTipoA:=_dDtTipoA
       _dDtLTipoB:=_dDtTipoB
       _dDtLTipoC:=_dDtTipoC
       _dDtLTipoD:=_dDtTipoD
       _dDtLTipoE:=_dDtTipoE
       _dDtLTipoF:=_dDtTipoF
    EndIf
    SF2->(DBSetOrder(1)) // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
    If SF2->(MsSeek(_cZF5Filial +  _cZF5DOCOC +  _cZF5SEROC + _cZF5CLIENT + _cZF5LOJA))

       SC5->(DBSetOrder(1))
       SC5->(DBSeek(_cZF5Filial+_cPedido))
       _cLOG:="F2_FILIAL          ;F2_DOC          ;F2_I_PEDID         ;C5_FILIAL          ;C5_NUM         ;C5_I_AGEND         ;C5_I_DTENT               ;F2_I_PENOL - A           ;F2_I_PENCL - A - C - F   ;F2_I_DCHOL - B           ;F2_I_DENOL - C           ;F2_I_DCHCL - D           ;F2_I_DENCL - E           ;F2_I_TT1TR                     ;F2_I_TT2TR                     ;C5_I_OPER          ;C5_TIPO         ;F2_I_REDP          ;F2_I_OPER"+CRLF
       _cLOG+="'"+SF2->F2_FILIAL+";'"+SF2->F2_DOC+";"+SF2->F2_I_PEDID+";'"+SC5->C5_FILIAL+";"+SC5->C5_NUM+";"+SC5->C5_I_AGEND+";"+DToC(SC5->C5_I_DTENT)+";"+DToC(SF2->F2_I_PENOL)+";"+DToC(SF2->F2_I_PENCL)+";"+DToC(SF2->F2_I_DCHOL)+";"+DToC(SF2->F2_I_DENOL)+";"+DToC(SF2->F2_I_DCHCL)+";"+DToC(SF2->F2_I_DENCL)+";"+cValToChar(SF2->F2_I_TT1TR)+";"+cValToChar(SF2->F2_I_TT2TR)+";'"+SC5->C5_I_OPER+";"+SC5->C5_TIPO+";'"+SF2->F2_I_REDP+";'"+SF2->F2_I_OPER+CRLF

       SF2->(RecLock("SF2",.F.))

       //TIPO A
       If !Empty(_dDtTipoA)// PREVISÃO DE ENTREGA no operador logístico
          _aDatas:=U_CalcTransiTime(_dDtTipoA)
          _dDataTTUCOP:=_aDatas[1]      // Data com Transit-time da Unidade de Carregamento até o Operador Logístico
          _dDataTTEOPC:=_aDatas[2]      // Data com Transit Time do Endereço (do Operador Logístico ou da Italac) até o Cliente
          If _lGravaSF2
          
             _cListaSF2+="A;SF2->F2_I_PENOL;"+DToC(SF2->F2_I_PENOL)+";"
             If !Empty(SF2->F2_I_REDP) .Or. !Empty(SF2->F2_I_OPER)
                SF2->F2_I_PENOL :=_dDataTTUCOP// PREVISÃO DE ENTREGA NO OPERADOR LOGÍSTICO ** SF2 **
             EndIf
             _cListaSF2+=DToC(SF2->F2_I_PENOL)+";Data com TT da Unid. de Carreg. ate o Oper.:;"+DToC(_dDataTTUCOP)+CRLF
          
             _cListaSF2+="A;SF2->F2_I_PENCL;"+DToC(SF2->F2_I_PENCL)+";"
             SF2->F2_I_PENCL := _dDataTTEOPC // PREVISÃO DE ENTREGA NO CLIENTE ** SF2 **
             _cListaSF2+=DToC(SF2->F2_I_PENCL)+";Data com TT do Oper. ate o Cliente:;"+DToC(_dDataTTEOPC)+CRLF
             
             _cListaSF2+="A;SF2->F2_I_PENCO;"+DToC(SF2->F2_I_PENCO)+";"
             If !(SC5->C5_I_AGEND == "M" .Or. SC5->C5_I_AGEND == "A")
                SF2->F2_I_PENCO := SF2->F2_I_PENCL
             EndIf
             _cListaSF2+=DToC(SF2->F2_I_PENCO)+";Data Previsão de entrega no cliente (original):;"+DToC(SF2->F2_I_PENCL)+CRLF
          
          Else// _cOrigem = "M460FIM_LER"
             _dTADtTTUCOP:=_dDataTTUCOP
             _dTADtTTEOPC:= _dDataTTEOPC    // PREVISÃO DE ENTREGA NO CLIENTE
             If !(SC5->C5_I_AGEND == "M" .Or. SC5->C5_I_AGEND == "A")
                _dTADtPENCO := _dTADtTTEOPC
             EndIf
             
          EndIf
       EndIf

       If (!Empty(SF2->F2_I_REDP) .Or. !Empty(SF2->F2_I_OPER))
          //TIPO B
          // Data de CHEGADA no operador logístico

          If _lGravaSF2
             _cListaSF2+="B;SF2->F2_I_DCHOL;"+DToC(SF2->F2_I_DCHOL)+";"
             SF2->F2_I_DCHOL := _dDtTipoB // DATA DE CHEGADA NO OPERADOR LOGÍSTICO ** SF2 **
             _cListaSF2+=DToC(SF2->F2_I_DCHOL)+CRLF

             //TIPO C
             //DATA DE ENTREGA NO OPERADOR LOGÍSTICO  EDI
             _cListaSF2+="C;SF2->F2_I_DENOL;"+DToC(SF2->F2_I_DENOL)+";"
             SF2->F2_I_DENOL := _dDtTipoC   // DATA DE ENTREGA NO OPERADOR LOGÍSTICO  EDI ** SF2 **
             _cListaSF2+=DToC(SF2->F2_I_DENOL)+CRLF
          EndIf

           // PREVISÃO de entrega no cliente em cima do TIPO B e TIPO C se tiver preenchido 1 das 2
           _dDataTTEOPC:=_dDtTipoB
           If _dDtTipoC > _dDtTipoB
              _dDataTTEOPC:=_dDtTipoC
           EndIf
           If !Empty(_dDataTTEOPC)
              _aDatas     :=U_CalcTransiTime(,_dDataTTEOPC)
              _dDataTTEOPC:=_aDatas[2]   // Data com Transit Time do Endereço do Operador Logístico até o Cliente
              If _lGravaSF2
                 _cListaSF2+="C;SF2->F2_I_PENCL;"+DToC(SF2->F2_I_PENCL)+";"
                 SF2->F2_I_PENCL := _dDataTTEOPC // PREVISÃO DE ENTREGA NO CLIENTE ** SF2 **
                 _cListaSF2+=DToC(SF2->F2_I_PENCL)+";Data com TT do Oper. ate o Cliente:;"+DToC(_dDataTTEOPC)+CRLF
              Else// _cOrigem = "M460FIM_LER"
                 _dTCDtTTEOPC:=_dTBDtTTEOPC:=_dDataTTEOPC
                 _dTCDtTTEOPC:=_dTBDtTTEOPC:=SC5->C5_I_DTENT
              EndIf
           EndIf

       EndIf

       //TIPO D
       If _lGravaSF2//!Empty(_dDtTipoD) //.AND. Empty(SF2->F2_I_DCHCL) // retirado pq a Ocorrencia anterior pode ser deletada
          _cListaSF2+="D;SF2->F2_I_DCHCL;"+DToC(SF2->F2_I_DCHCL)+";"
          SF2->F2_I_DCHCL := _dDtTipoD // Data de CHEGADA no cliente ** SF2 **
          _cListaSF2+=DToC(SF2->F2_I_DCHCL)+CRLF
       EndIf

       //TIPO "E"
       If _lGravaSF2//!Empty(_dDtTipoE) //.And. Empty(SF2->F2_I_DENCL)// retirado pq a Ocorrencia anterior pode ser deletada
          _cListaSF2+="E;SF2->F2_I_DENCL;"+DToC(SF2->F2_I_DENCL)+";"
           SF2->F2_I_DENCL := _dDtTipoE // Data de ENTREGA no cliente ** SF2 **
          _cListaSF2+=DToC(SF2->F2_I_DENCL)+CRLF
       EndIf

       //TIPO "F"
       If !Empty(_dDtTipoF) .And. _lGravaSF2// REAGENDAMENTRO DE ENTREGA
          _cListaSF2+="F;SF2->F2_I_PENCL;"+DToC(SF2->F2_I_PENCL)+";"
          SF2->F2_I_PENCL := _dDtTipoF // PREVISÃO de entrega no cliente ** SF2 **
          _cListaSF2+=DToC(SF2->F2_I_PENCL)+CRLF
       EndIf

       // ZFC_OLREDI = "S"
       If !Empty(_dDtREOPL_S) .And. _lGravaSF2//Redirecionamento de operador logístico
          SF2->F2_I_OLRDT := _dDtREOPL_S  // ZF5_DTOCOR  - Data do redirecionamento para operador logístico
          SF2->F2_I_OLRCD := _cZF5_OLRCOD // ZF5_OLRCOD - Código do operador logístico do redirecionamento
          SF2->F2_I_OLRLJ := _cZF5_OLRLOJ // ZF5_OLRLOJ - Loja do operador logístico do redirecionamento
       EndIf

       SF2->(MSUnLock())

       If SuperGetMV("IT_GLOGDTO",.T.,.F.) .Or. !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
          _cLOG     := "AMBIENTE:;"+AllTrim(GETENVSERVER())+";Origem:;"+_cOrigem+CRLF+_cLOG
          _cLOG     += CRLF
          _cLOG     += _cListaOco+CRLF
          _cLOG     += _cListaSF2+CRLF
          _cFileNome:= "/data/logs_generico/aoms003_"+SF2->F2_FILIAL+"_"+AllTrim(SF2->F2_DOC)+"_"+DToS(DATE())+"_"+StrTran(TIME(),":","_")+".csv"

          MemoWrite(LOWER(_cFileNome),_cLOG)

       EndIf

       If _lGravaSF2
          U_ReplDatasTransTime( SF2->(RECNO()) , _lTesteNF )
       EndIf

    EndIf
 EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS03Leg
Autor-------------: Alex Wallauer
Data da Criacao---: 26/12/2024
Descrição---------: Tratamentos da Legenda
Parametros--------: Se _lLegenda = .T. devolve a cor da legenda, senão exibe a legenda.
Retorno-----------: Cor da Legenda ou .T.
===============================================================================================================================*/
Static Function AOMS03Leg(_lLegenda)
 
 Local _cRetorno As Char
 Local _aLegenda As Array
 Local _oModel  As Object
 Local _oModelGrid As Object
 Local _nLine  As Numeric
 Local _cEstonado := "N" As Char
 Local _cStatus   As Char

 If _lLegenda//GRAVAÇÃO DO CAMPO LEGENDA
    _oModel    := FWModelActive()
    _oModelGrid:= _oModel:GetModel("ZF5DETAIL")
    _nLine     := _oModelGrid:GetLine()
    _cRetorno  := "BR_AMARELO"
    If _nLine > 0 //VIA TELA
       _cEstonado :=_oModelGrid:GetValue("ZF5_ESTONO")
       _cStatus   :=_oModelGrid:GetValue("ZF5_APRREJ")
    Else// CARGA INICAL NA ALTERAÇÃO
       _cEstonado := ZF5->ZF5_ESTONO
       _cStatus   := ZF5->ZF5_APRREJ
    EndIf
    Do Case
       Case _cEstonado ='S'
           _cRetorno := "BR_PRETO"
       Case _cStatus ='A'
           _cRetorno := "BR_VERDE"
       Case _cStatus ='R'
           _cRetorno := "BR_VERMELHO"
    End Case
    Return _cRetorno// **** SAIDA ****
 Else//WHEN DO CAMPO LEGENDA
    _aLegenda := {}
    aAdd( _aLegenda, { "BR_VERDE"    ,      "Aprovada"  })
    aAdd( _aLegenda, { "BR_VERMELHO" ,      "Rejeitada" })
    aAdd( _aLegenda, { "BR_PRETO"    ,      "Estornada" })
    aAdd( _aLegenda, { "BR_AMARELO"  ,      "Pendente"  })
    BrwLegenda( "Status das ocorrencias", "Legenda", _aLegenda )
 EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: BuscaRecZF5
Autor-------------: Alex Wallauer
Data da Criacao---: 02/06/2025
Descrição---------: Busca a lista de recnos do ZF5
Parametros--------: _cNotaFiscal as char, _cSerie as char
Retorno-----------: _aRecZF5
===============================================================================================================================*/
Static Function BuscaRecZF5(_cFilail as char, _cNotaFiscal as char, _cSerie as char)

Local _cQuery  := "" As Char
Local _aRecZF5 :={} As Array
Local _cAlias  := GetNextAlias()
 
_cQuery += " SELECT ZF5A.R_E_C_N_O_ AS RECZF5 "
_cQuery += "     FROM ZF5010 ZF5A, "
_cQuery += "          ZFC010 ZFCA, "
_cQuery += "          SF2010 SF2, "
_cQuery += "          SC5010 SC5 "
_cQuery += "    WHERE     F2_FILIAL = '"+_cFilail+"' "
_cQuery += "          AND F2_DOC = '"+_cNotaFiscal+"' "
_cQuery += "          AND F2_SERIE = '"+_cSerie+"' "
_cQuery += "          AND SF2.D_E_L_E_T_ = ' ' "
_cQuery += "          AND ZF5A.ZF5_FILIAL = F2_FILIAL "
_cQuery += "          AND ZF5A.ZF5_DOCOC = F2_DOC "
_cQuery += "          AND ZF5A.ZF5_SEROC = F2_SERIE "
_cQuery += "          AND ZF5A.ZF5_ESTONO <> 'S' "
_cQuery += "          AND ZF5A.ZF5_DTOCOR >= F2_EMISSAO "
_cQuery += "          AND ZF5A.D_E_L_E_T_ = ' ' "
_cQuery += "          AND ZFCA.ZFC_FILIAL = ' ' "
_cQuery += "          AND ZFCA.ZFC_CODIGO = ZF5A.ZF5_TIPOO "
_cQuery += "          AND ZFCA.ZFC_DTTRAN <> ' ' "
_cQuery += "          AND ZFCA.D_E_L_E_T_ = ' ' "
_cQuery += "          AND C5_FILIAL = F2_FILIAL "
_cQuery += "          AND C5_NUM = F2_I_PEDID "
_cQuery += "          AND SC5.D_E_L_E_T_ = ' ' "
_cQuery += "          AND ZF5A.R_E_C_N_O_ = "
_cQuery += "              Case "
_cQuery += "                  WHEN ZFCA.ZFC_DTTRAN IN ('B', "
_cQuery += "                                           'C', "
_cQuery += "                                           'D', "
_cQuery += "                                           'E') "
_cQuery += "                  THEN "
_cQuery += "                      (SELECT MIN (ZF5B.R_E_C_N_O_) "
_cQuery += "                         FROM ZF5010 ZF5B, ZFC010 ZFCB "
_cQuery += "                        WHERE     ZF5B.ZF5_FILIAL = ZF5A.ZF5_FILIAL "
_cQuery += "                              AND ZF5B.ZF5_DOCOC = ZF5A.ZF5_DOCOC "
_cQuery += "                              AND ZF5B.ZF5_SEROC = ZF5A.ZF5_SEROC "
_cQuery += "                              AND ZF5B.ZF5_ESTONO <> 'S' "
_cQuery += "                              AND ZF5B.ZF5_DTOCOR >= F2_EMISSAO "
_cQuery += "                              AND ZF5B.D_E_L_E_T_ = ' ' "
_cQuery += "                              AND ZFCB.ZFC_FILIAL = ' ' "
_cQuery += "                              AND ZFCB.ZFC_CODIGO = ZF5B.ZF5_TIPOO "
_cQuery += "                              AND ZFCB.ZFC_DTTRAN = ZFCA.ZFC_DTTRAN "
_cQuery += "                              AND ZFCB.D_E_L_E_T_ = ' ') "
_cQuery += "                  Else "
_cQuery += "                      (SELECT MAX (ZF5B.R_E_C_N_O_) "
_cQuery += "                         FROM ZF5010 ZF5B, ZFC010 ZFCB "
_cQuery += "                        WHERE     ZF5B.ZF5_FILIAL = ZF5A.ZF5_FILIAL "
_cQuery += "                              AND ZF5B.ZF5_DOCOC = ZF5A.ZF5_DOCOC "
_cQuery += "                              AND ZF5B.ZF5_SEROC = ZF5A.ZF5_SEROC "
_cQuery += "                              AND ZF5B.ZF5_ESTONO <> 'S' "
_cQuery += "                              AND ZF5B.ZF5_DTOCOR >= F2_EMISSAO "
_cQuery += "                              AND ZF5B.D_E_L_E_T_ = ' ' "
_cQuery += "                              AND ZFCB.ZFC_FILIAL = ' ' "
_cQuery += "                              AND ZFCB.ZFC_CODIGO = ZF5B.ZF5_TIPOO "
_cQuery += "                              AND ZFCB.ZFC_DTTRAN = ZFCA.ZFC_DTTRAN "
_cQuery += "                              AND ZFCB.D_E_L_E_T_ = ' ') "
_cQuery += "              END "
_cQuery += " ORDER BY ZF5A.R_E_C_N_O_ "
 
 MPSysOpenQuery( _cQuery , _cAlias )
 While (_cAlias)->(!Eof())
    aAdd( _aRecZF5, (_cAlias)->RECZF5 )
    (_cAlias)->(DBSkip())  
 EndDo
 (_cAlias)->(DBCloseArea())

Return _aRecZF5
