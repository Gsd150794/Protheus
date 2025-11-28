/*
==============================================================================================================================================================
         ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
==============================================================================================================================================================
Analista     - Programador   - Inicio   - Envio      - Chamado - Motivo da Alteração
===============================================================================================================================================================
Antônio Ramos - Julio Paz    - 08/09/25 - 30/10/25   - 48153   - Rotina de geração de dados e emissão do relatório do Fechamanto Financeiro.
===============================================================================================================================================================
*/

#include "Protheus.ch"
#INCLUDE "TBICONN.ch"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "PARMTYPE.ch"

Static _aCabec   := {}  As Array
Static _aItem    := {}  As Array
Static _cAbas    := ""  As Character

/*
===============================================================================================================================
Função-------------: AFIN040
Autor--------------: Julio de Paula Paz
Data da Criacao----: 08/09/2025
Descrição----------: Rotina de geração de dados e emissão de relatório do Fechamento Financeiro. Chamado 48153.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function AFIN040()

    Local _aSizeAut   := MsAdvSize(.T.)             As Array
    Local _aFolders   := {}                         As Array
    Local _aParAux    := {}                         As Array
    Local _aParRet    := {}                         As Array
    Local _aFieldCab  := {}                         As Array
    Local _aFieldDet  := {}                         As Array
    Local _aAbas      := {}                         As Array
    Local _aObjects   := {}                         As Array
    Local _aInfo      := {}                         As Array
    Local _aPosObj    := {}                         As Array
    Local _cTitulo    := ""                         As Character
    Local _nMes       := 0                          As Numeric
    Local _nAno       := 0                          As Numeric
    Local _nFor       := 0                          As Numeric
    Local _nPosAba    := 0                          As Numeric
    Local _dDtDia     := Date()                     As Date
    Local _dDtIni     := Date()                     As Date
    Local _oDlgFin    := Nil                        As Object

    _aAbas := {"00-Todas", ;
    "01-Emissão Dentro do Mês", ;
    "02-Faturamento Manual no Mês", ;
    "03-Recebimento de Crédito no Mês", ;
    "04-Desmembramento no Mês", ;
    "05-Total Superior 4 meses", ;
    "06-Total Faturamentos do 4º mês anterior", ;
    "07-Total 3o Mes Anterior", ;
    "08-Total 2o Mes Anterior", ;
    "09-Total 1o Mes Anterior", ;
    "10-Total 1o Mes Seguinte", ;
    "11-Total 2o Mes Seguinte", ;
    "12-Total 3o Mes Seguinte", ;
    "13-Total 4o Mes Seguinte", ;
    "14-Total Superior ao 4o Mes", ;
    "15-Total Emitidas e Vencidas no Mesmo Mes", ;
    "16-Total Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes", ;
    "17-Vendas do Mes Recebidas no Mes", ;
    "18-Devolvidas-RA Compensadas", ;
    "19-Devolvidas-NCC Compensadas no Mês(Tipos NF com NCC)" ;
    }

    _dDtDia  := Date()
    _nMes    := Val(Substr(Dtos(_dDtDia),5,2))
    _nAno    := Val(Substr(Dtos(_dDtDia),1,4))
    _dDtIni  := Ctod("01/"+StrZero(_nMes,2)+"/"+StrZero(_nAno,4))

    MV_PAR01 := StrZero(_nMes,2)+StrZero(_nAno,4)
    MV_PAR02 := "1"
    MV_PAR03 := Space(100)
    MV_PAR04 := "00"

    AAdd( _aParAux , { 1 , "Mês/Ano"           , MV_PAR01, "@R 99/9999"    , ""   , ""    , ""   , 030   , .T. } )
    AAdd( _aParAux , { 2 , "Tipo Processamento", MV_PAR02, {"1-Gerar Dados","2-Consultar Dados"} , 070   ,".T." ,.T.,".T."})
    AAdd( _aParAux , { 1 , "Filial:"           , MV_PAR03, "@!","","LSTFIL",'',100,.F.})
    AAdd( _aParAux , { 2 , "Selecionar Abas"   , MV_PAR05 , _aAbas, 100 , ".T." , .F. , ".T." } )

    AAdd(_aParRet,"MV_PAR01")
    AAdd(_aParRet,"MV_PAR02")
    AAdd(_aParRet,"MV_PAR03")
    AAdd(_aParRet,"MV_PAR04")

    If !ParamBox( _aParAux , "Geração/Consulta de Dados - Fechamento Financeiro" , @_aParRet )
        U_ItMsg( "Operação cancelada pelo usuário!" , "Atenção!",,1 )
        Break
    EndIf

    If Empty(MV_PAR01)         
        U_ItMsg( "O período para processamento não foi i_nFormado!" , "Atenção!",,1 )
        Break
    EndIf 

    If Val(SubStr(MV_PAR01,1,2)) < 1 .Or. Val(SubStr(MV_PAR01,1,2)) > 12 
        U_ItMsg( "O mês i_nFormado para processamento é inválido." , "Atenção!",,1 )
        Break
    EndIf

    //Adiciona as abas selecionadas.
    _cAbas := SubStr( MV_PAR04 , 1 , 2 )
    If _cAbas <> "00"
        _nPosAba := aScan(_aAbas, {|x| SubStr(x, 1, 2) == _cAbas})
        AAdd(_aFolders, _aAbas[_nPosAba])
    Else
        For _nFor := 1 To 20
        If _aAbas[_nFor] <> "00-Todas"
            AAdd(_aFolders, _aAbas[_nFor])
        EndIf
        Next _nFor
    Endif

    Processa( {|| AFIN040A() } , 'Aguarde!' , 'Criando tabelas temporárias...' )

    If SubStr(MV_PAR02,1,1) == "1" // 1-Gerar Dados
        Processa( {|| AFIN040B() } , 'Aguarde!' , 'Gerando dados para o Fechamento Financeiro...' )
    Else 
        Processa( {|| AFIN040D() } , 'Aguarde!' , 'Consultando dados do Fechamento Financeiro...' )
    EndIf 

    ProcRegua(0)
    IncProc('Inicializando a rotina...')

    _cTitulo := "Fechamento Financeiro - Período: " + SubStr(MV_PAR01,1,2) + "/" + SubStr(MV_PAR01,3,4)

    _aObjects := {}
    AAdd( _aObjects, { 315,  50, .T., .T. } )
    AAdd( _aObjects, { 100, 100, .T., .T. } )

    _aInfo := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 }

    _aPosObj := MsObjSize( _aInfo, _aObjects, .T. )

    //==============================
    // Define campos Sintético
    //==============================
    AAdd(_aFieldCab ,{Getsx3cache("ZCA_VISAO" ,"X3_TITULO"), "ZCA_VISAO" , "C", Getsx3cache("ZCA_VISAO" ,"X3_TAMANHO") ,0, Getsx3cache("ZCA_VISAO" ,"X3_PICTURE")})     //	Item Visao
    AAdd(_aFieldCab ,{Getsx3cache("ZCA_DESVIS","X3_TITULO"), "ZCA_DESVIS", "C", Getsx3cache("ZCA_DESVIS","X3_TAMANHO") ,0,Getsx3cache("ZCA_DESVIS","X3_PICTURE")})      //	Descr.Visao
    AAdd(_aFieldCab ,{Getsx3cache("ZCA_FILVIS","X3_TITULO"), "ZCA_FILVIS", "C", Getsx3cache("ZCA_FILVIS","X3_TAMANHO") ,0,Getsx3cache("ZCA_FILVIS","X3_PICTURE"),0 ,})  //	Filial Visao
    AAdd(_aFieldCab ,{Getsx3cache("ZCA_VALOR" ,"X3_TITULO"), "ZCA_VALOR" , "N", Getsx3cache("ZCA_VALOR" ,"X3_TAMANHO") ,Getsx3cache("ZCA_VALOR","X3_DECIMAL"),Getsx3cache("ZCA_VALOR" ,"X3_PICTURE")}) //	Valor Filial
    AAdd(_aFieldCab ,{Getsx3cache("ZCA_VERSAO","X3_TITULO"), "ZCA_VERSAO", "C", Getsx3cache("ZCA_VERSAO","X3_TAMANHO") ,0,Getsx3cache("ZCA_VERSAO","X3_PICTURE")})      //	Versão
    AAdd(_aFieldCab ,{Getsx3cache("ZCA_MESANO","X3_TITULO"), "ZCA_MESANO", "C", Getsx3cache("ZCA_MESANO","X3_TAMANHO") ,0,Getsx3cache("ZCA_MESANO","X3_PICTURE")})      //	Mês/Ano Emis
    AAdd(_aFieldCab ,{Getsx3cache("ZCA_DTEMIS","X3_TITULO"), "ZCA_DTEMIS", "D", 8,	0,})                                                                                //	Data Emissao
    AAdd(_aFieldCab ,{Getsx3cache("ZCA_HREMIS","X3_TITULO"), "ZCA_HREMIS", "C", Getsx3cache("ZCA_HREMIS","X3_TAMANHO") ,0,Getsx3cache("ZCA_HREMIS","X3_PICTURE")})      //	Hora Emissao
    AAdd(_aFieldCab ,{Getsx3cache("ZCA_USUARI","X3_TITULO"), "ZCA_USUARI", "C", Getsx3cache("ZCA_USUARI","X3_TAMANHO") ,0,Getsx3cache("ZCA_USUARI","X3_PICTURE")})      //	Usuario Fech

    //==============================
    // Define campos Analíticos
    //==============================
    AAdd(_aFieldDet ,{Getsx3cache("ZCB_VISAO"  ,"X3_TITULO"), "ZCB_VISAO" , "C", Getsx3cache("ZCB_VISAO" ,"X3_TAMANHO") ,0}) //	Item Visao
    AAdd(_aFieldDet ,{Getsx3cache("ZCB_FILVIS" ,"X3_TITULO"), "ZCB_FILVIS", "C", Getsx3cache("ZCB_FILVIS","X3_TAMANHO") ,0}) //	Filial Visao
    AAdd(_aFieldDet ,{Getsx3cache("ZCB_VERSAO" ,"X3_TITULO"), "ZCB_VERSAO", "C", Getsx3cache("ZCB_VERSAO","X3_TAMANHO") ,0}) //	Versão
    AAdd(_aFieldDet ,{Getsx3cache("ZCB_MESANO" ,"X3_TITULO"), "ZCB_MESANO", "C", Getsx3cache("ZCB_MESANO","X3_TAMANHO") ,0}) //	Mês/Ano Emis
    AAdd(_aFieldDet ,{Getsx3cache("ZCB_DTEMIS" ,"X3_TITULO"), "ZCB_DTEMIS", "D", 8 ,0})                                      //	Data Emissao
    AAdd(_aFieldDet ,{Getsx3cache("ZCB_HREMIS" ,"X3_TITULO"), "ZCB_HREMIS", "C", Getsx3cache("ZCB_HREMIS","X3_TAMANHO") ,0}) //	Hora Emissao
    AAdd(_aFieldDet ,{Getsx3cache("ZCB_USUARI" ,"X3_TITULO"), "ZCB_USUARI", "C", Getsx3cache("ZCB_USUARI","X3_TAMANHO") ,0}) //	Usuario Fech
    AAdd(_aFieldDet ,{Getsx3cache("ZCB_NUMTIT" ,"X3_TITULO"), "ZCB_NUMTIT", "C", Getsx3cache("ZCB_NUMTIT","X3_TAMANHO") ,0}) //	No. Titulo  
    AAdd(_aFieldDet ,{Getsx3cache("ZCB_PREFIX" ,"X3_TITULO"), "ZCB_PREFIX", "C", Getsx3cache("ZCB_PREFIX","X3_TAMANHO") ,0}) //	Prefixo     
    AAdd(_aFieldDet ,{Getsx3cache("ZCB_PARCEL" ,"X3_TITULO"), "ZCB_PARCEL", "C", Getsx3cache("ZCB_PREFIX","X3_TAMANHO") ,0}) //	Parcerla
    AAdd(_aFieldDet ,{Getsx3cache("ZCB_TIPO"   ,"X3_TITULO"), "ZCB_TIPO"  , "C", Getsx3cache("ZCB_TIPO"  ,"X3_TAMANHO") ,0}) //	Tipo
    AAdd(_aFieldDet ,{Getsx3cache("ZCB_CLIENT" ,"X3_TITULO"), "ZCB_CLIENT", "C", Getsx3cache("ZCB_CLIENT","X3_TAMANHO") ,0}) //	Cliente 
    AAdd(_aFieldDet ,{Getsx3cache("ZCB_LOJA"   ,"X3_TITULO"), "ZCB_LOJA"  , "C", Getsx3cache("ZCB_PREFIX","X3_TAMANHO") ,0}) //	Loja
    AAdd(_aFieldDet ,{Getsx3cache("ZCB_NOMCLI" ,"X3_TITULO"), "ZCB_NOMCLI", "C", Getsx3cache("ZCB_LOJA"  ,"X3_TAMANHO") ,0}) //	Nome
    AAdd(_aFieldDet ,{Getsx3cache("ZCB_VALOR"  ,"X3_TITULO"), "ZCB_VALOR" , "C", Getsx3cache("ZCB_VALOR" ,"X3_TAMANHO") ,Getsx3cache("ZCB_VALOR","X3_DECIMAL")}) //	Valor
    AAdd(_aFieldDet ,{Getsx3cache("ZCB_EMISSA" ,"X3_TITULO"), "ZCB_EMISSA", "D", 8 ,0})                                      //	Emissão

    DEFINE MSDIALOG _oDlgFin TITLE _cTitulo From 0,0 To _aSizeAut[6], _aSizeAut[5] PIXEL

    oTFolder1:= TFolder():New( 1,1, _aFolders,,_oDlgFin,,,,.T., , _aSizeAut[6], _aSizeAut[5] )
    oTFont := Nil

    //===============================================================
    // FwMarkBrowser - "01-Emissão Dentro do Mês" = A
    //===============================================================
    If _cAbas == "00" .Or. _cAbas == "01"
        _cAliasCab := "TRBCAB_A"
        _cAliasDet := "TRBDET_A"
        oPanel1A := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
        oPanel2A := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)  

        // Sintético
        oMarkBRW1A := FWMarkBrowse():New()		   							// Inicializa o Browse
        oMarkBRW1A:SetAlias( _cAliasCab)			   						// Define Alias que será a Base do Browse
        oMarkBRW1A:SetDescription( "01-Emissão Dentro do Mês - Sintético")	// Define o titulo do browse de marcacao
        oMarkBRW1A:SetFields(_aFieldCab)									// Campos para exibição
        oMarkBRW1A:SetOwner(oPanel1A)                                       // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1A:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW1A:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("01-Emissão Dentro do Mês") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 ) 
        oMarkBRW1A:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1A:Activate()								                // Ativacao da classe

        // Analítico
        oMarkBRW2A := FWMarkBrowse():New()		   							// Inicializa o Browse
        oMarkBRW2A:SetAlias( _cAliasDet)			   				        // Define Alias que será a Base do Browse
        oMarkBRW2A:SetDescription( "01-Emissão Dentro do Mês - Analítico")	// Define o titulo do browse de marcacao
        oMarkBRW2A:SetFields(_aFieldDet)									// Campos para exibição
        oMarkBRW2A:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW2A:SetOwner(oPanel2A)                                       // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW2A:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("A","01") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2A:Activate()                                               // Ativacao da classe

        If _cAbas == "01"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1A:Align:= CONTROL_ALIGN_TOP , oPanel2A:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf 
    EndIf 

    //===============================================================
    // FwMarkBrowser - 02-Faturamento Manual no Mês" = B
    //===============================================================
    If _cAbas == "00" .Or. _cAbas == "02"
        _cAliasCab := "TRBCAB_B"
        _cAliasDet := "TRBDET_B"

        If _cAbas == "02"
            oPanel1B := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2B := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1B := tPanel():New(01,01,"",oTFolder1:aDialogs[2], ,.T.,,,, 100, 100)
            oPanel2B := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[2],,.T.,,,, 500, 200)
        EndIf

        oPanel1B:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2B:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

            // Sintético
        oMarkBRW1B1 := FWMarkBrowse():New()		   					// Inicializa o Browse
        oMarkBRW1B1:SetAlias( _cAliasCab)			   				// Define Alias que será a Base do Browse
        oMarkBRW1B1:SetDescription( "02-Faturamento Manual no Mês")	// Define o titulo do browse de marcacao
        oMarkBRW1B1:SetFields(_aFieldCab)					        // Campos para exibição
        oMarkBRW1B1:SetOwner(oPanel1B)                              // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1B1:DisableReport()                                 // Desabilita botões padrões
        oMarkBRW1B1:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("02-Faturamento Manual no Mês") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1B1:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1B1:Activate()						                // Ativacao da classe

            // Analítico
        oMarkBRW2B2 := FWMarkBrowse():New()		   					// Inicializa o Browse
        oMarkBRW2B2:SetAlias( _cAliasDet)			   			    // Define Alias que será a Base do Browse
        oMarkBRW2B2:SetDescription( "02-Faturamento Manual no Mês")	// Define o titulo do browse de marcacao
        oMarkBRW2B2:SetFields(_aFieldDet)							// Campos para exibição
        oMarkBRW2B2:DisableReport()                                 // Desabilita botões padrões
        oMarkBRW2B2:SetOwner(oPanel2B)                              // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW2B2:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("B","02") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2B2:Activate()                                      // Ativacao da classe    
        
        If _cAbas == "02"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1B:Align:= CONTROL_ALIGN_TOP , oPanel2B:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf 	                                                         
    EndIf

    //===============================================================
    // FwMarkBrowser - 03-Recebimento de Crédito no Mês" = C
    //===============================================================
    If _cAbas == "00" .Or. _cAbas == "03"
        _cAliasCab := "TRBCAB_C"
        _cAliasDet := "TRBDET_C"

        If _cAbas == "03"
            oPanel1C := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2C := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1C := tPanel():New(01,01,"",oTFolder1:aDialogs[3], ,.T.,,,, 100, 100)
            oPanel2C := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[3],,.T.,,,, 500, 200)
        EndIf

        oPanel1C:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2C:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

        // Sintético
        oMarkBRW1C := FWMarkBrowse():New()		   									// Inicializa o Browse
        oMarkBRW1C:SetAlias( _cAliasCab)			   								// Define Alias que será a Base do Browse
        oMarkBRW1C:SetDescription("03-Recebimento de Crédito no Mês - Sintético")	// Define o titulo do browse de marcacao
        oMarkBRW1C:SetFields(_aFieldCab)											// Campos para exibição
        oMarkBRW1C:SetOwner(oPanel1C)                                               // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1C:DisableReport()                                                  // Desabilita botões padrões
        oMarkBRW1C:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("03-Recebimento de Crédito no Mês") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1C:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1C:Activate()														// Ativacao da classe

        // Analítico
        oMarkBRW2C := FWMarkBrowse():New()		   								    // Inicializa o Browse
        oMarkBRW2C:SetAlias( _cAliasDet)			   								// Define Alias que será a Base do Browse
        oMarkBRW2C:SetDescription("03-Recebimento de Crédito no Mês - Analítico")	// Define o titulo do browse de marcacao
        oMarkBRW2C:SetFields(_aFieldDet)											// Campos para exibição
        oMarkBRW2C:SetOwner(oPanel2C)                                               // Define o objeto da tela onde os dados serão exibidos 
        oMarkBRW2C:DisableReport()                                                  // Desabilita botões padrões
        oMarkBRW2C:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("C","03") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2C:Activate()														// Ativacao da classe

        If _cAbas == "03"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1C:Align:= CONTROL_ALIGN_TOP , oPanel2C:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf
    EndIf

    //===============================================================
    // FwMarkBrowser - 04-Desmembramento no Mês" = D
    //===============================================================
    If _cAbas == "00" .Or. _cAbas == "04"
        _cAliasCab := "TRBCAB_D"
        _cAliasDet := "TRBDET_D"

        If _cAbas == "04"
            oPanel1D := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2D := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1D := tPanel():New(01,01,"",oTFolder1:aDialogs[4], ,.T.,,,, 100, 100)
            oPanel2D := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[4],,.T.,,,, 500, 200)
        EndIf

        oPanel1D:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2D:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

        // Sintético
        oMarkBRW1D := FWMarkBrowse():New()		   								// Inicializa o Browse
        oMarkBRW1D:SetAlias( _cAliasCab)			   						    // Define Alias que será a Base do Browse
        oMarkBRW1D:SetDescription( "04-Desmembramento no Mês - Sintético")	    // Define o titulo do browse de marcacao
        oMarkBRW1D:SetFields(_aFieldCab)										// Campos para exibição
        oMarkBRW1D:SetOwner(oPanel1D)                                           // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1D:DisableReport()                                              // Desabilita botões padrões
        oMarkBRW1D:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("04-Desmembramento no Mês") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1D:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1D:Activate()													// Ativacao da classe

        // Analítico
        oMarkBRW2D := FWMarkBrowse():New()		   								// Inicializa o Browse
        oMarkBRW2D:SetAlias( _cAliasDet)			   							// Define Alias que será a Base do Browse
        oMarkBRW2D:SetDescription( "04-Desmembramento no Mês - Analítico")	    // Define o titulo do browse de marcacao
        oMarkBRW2D:SetFields(_aFieldDet)										// Campos para exibição
        oMarkBRW2D:SetOwner(oPanel2D)                                           // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW2D:DisableReport()                                              // Desabilita botões padrões
        oMarkBRW2D:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("D","04") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2D:Activate()													// Ativacao da class  

        If _cAbas == "04"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1D:Align:= CONTROL_ALIGN_TOP , oPanel2D:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf
    EndIf

    //===============================================================
    // FwMarkBrowser - 05-Total-Superior 4 meses" = E
    //===============================================================
    If _cAbas == "00" .Or. _cAbas == "05"
        _cAliasCab := "TRBCAB_E"
        _cAliasDet := "TRBDET_E"
        
        If _cAbas == "05"
            oPanel1E := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2E := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1E := tPanel():New(01,01,"",oTFolder1:aDialogs[5], ,.T.,,,, 100, 100)
            oPanel2E := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[5],,.T.,,,, 500, 200)
        EndIf

        oPanel1E:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2E:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

        // Sintético
        oMarkBRW1E := FWMarkBrowse():New()		   						    // Inicializa o Browse
        oMarkBRW1E:SetAlias( _cAliasCab)			   						// Define Alias que será a Base do Browse
        oMarkBRW1E:SetDescription("05-Total-Superior 4 meses - Sintético")	// Define o titulo do browse de marcacao
        oMarkBRW1E:SetFields(_aFieldCab)									// Campos para exibição
        oMarkBRW1E:SetOwner(oPanel1E)                                       // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1E:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW1E:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("05-Total-Superior 4 meses") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1E:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1E:Activate()												// Ativacao da classe

        // Analítico
        oMarkBRW2E := FWMarkBrowse():New()		   							// Inicializa o Browse
        oMarkBRW2E:SetAlias( _cAliasDet)			   						// Define Alias que será a Base do Browse
        oMarkBRW2E:SetDescription("05-Total-Superior 4 meses - Analítico")	// Define o titulo do browse de marcacao
        oMarkBRW2E:SetFields(_aFieldDet)									// Campos para exibição
        oMarkBRW2E:SetOwner(oPanel2E)                                       // Define o objeto da tela onde os dados serão exibidos  
        oMarkBRW2E:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW2E:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("E","05") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2E:Activate()												// Ativacao da classe

        If _cAbas == "05"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1E:Align:= CONTROL_ALIGN_TOP , oPanel2E:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf   
    EndIf

    //=====================================================================
    // FwMarkBrowser - 06-Total-Faturamentos do 4º mês anterior" = F
    //=====================================================================
    If _cAbas == "00" .Or. _cAbas == "06"
        _cAliasCab := "TRBCAB_F"
        _cAliasDet := "TRBDET_F"

        If _cAbas == "06"
            oPanel1F := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2F := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1F := tPanel():New(01,01,"",oTFolder1:aDialogs[6], ,.T.,,,, 100, 100)
            oPanel2F := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[6],,.T.,,,, 500, 200)
        EndIf

        oPanel1F:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2F:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

        // Sintético
        oMarkBRW1F := FWMarkBrowse():New()		   										    // Inicializa o Browse
        oMarkBRW1F:SetAlias( _cAliasCab)			   										// Define Alias que será a Base do Browse
        oMarkBRW1F:SetDescription( "06-Total-Faturamentos do 4º mês anterior - Sintético")	// Define o titulo do browse de marcacao
        oMarkBRW1F:SetFields(_aFieldCab)													// Campos para exibição
        oMarkBRW1F:SetOwner(oPanel1F)                                                       // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1F:DisableReport()                                                          // Desabilita botões padrões
        oMarkBRW1F:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("06-Total-Faturamentos do 4º mês anterior") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1F:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1F:Activate()																// Ativacao da classe

        // Analítico
        oMarkBRW2F := FWMarkBrowse():New()		   										    // Inicializa o Browse
        oMarkBRW2F:SetAlias( _cAliasDet)			   										// Define Alias que será a Base do Browse
        oMarkBRW2F:SetDescription( "06-Total-Faturamentos do 4º mês anterior - Analítico")	// Define o titulo do browse de marcacao
        oMarkBRW2F:SetFields(_aFieldDet)													// Campos para exibição
        oMarkBRW2F:SetOwner(oPanel2F)                                                       // Define o objeto da tela onde os dados serão exibidos    
        oMarkBRW2F:DisableReport()                                                          // Desabilita botões padrões
        oMarkBRW2F:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("F","06") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2F:Activate()																// Ativacao da classe

        If _cAbas == "06"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1F:Align:= CONTROL_ALIGN_TOP , oPanel2F:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf 
    EndIf

    //===============================================================
    // FwMarkBrowser - 07-Total - 3o Mes Anterior" = G
    //===============================================================
    If _cAbas == "00" .Or. _cAbas == "07"
        _cAliasCab := "TRBCAB_G"
        _cAliasDet := "TRBDET_G"

        If _cAbas == "07"
            oPanel1G := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2G := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1G := tPanel():New(01,01,"",oTFolder1:aDialogs[7], ,.T.,,,, 100, 100)
            oPanel2G := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[7],,.T.,,,, 500, 200)
        EndIf

        oPanel1G:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2G:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

        // Sintético
        oMarkBRW1G := FWMarkBrowse():New()		   							// Inicializa o Browse
        oMarkBRW1G:SetAlias(_cAliasCab)			   							// Define Alias que será a Base do Browse
        oMarkBRW1G:SetDescription("07-Total -3o Mes Anterior - Sintético")	// Define o titulo do browse de marcacao
        oMarkBRW1G:SetFields(_aFieldCab)									// Campos para exibição
        oMarkBRW1G:SetOwner(oPanel1G)                                       // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1G:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW1G:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("07-Total -3o Mes Anterior") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1G:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1G:Activate()									            // Ativacao da classe

        // Analítico
        oMarkBRW2G := FWMarkBrowse():New()		   							// Inicializa o Browse
        oMarkBRW2G:SetAlias(_cAliasDet)			   							// Define Alias que será a Base do Browse
        oMarkBRW2G:SetDescription("07-Total -3o Mes Anterior - Analítico")	// Define o titulo do browse de marcacao
        oMarkBRW2G:SetFields(_aFieldDet)									// Campos para exibição
        oMarkBRW2G:SetOwner(oPanel2G)                                       // Define o objeto da tela onde os dados serão exibidos    
        oMarkBRW2G:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW2G:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("G","07") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2G:Activate()												// Ativacao da classe

        If _cAbas == "07"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1G:Align:= CONTROL_ALIGN_TOP , oPanel2G:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf 
    EndIf

    //===============================================================
    // FwMarkBrowser - 08-Total-2o Mes Anterior" = H
    //===============================================================
    If _cAbas == "00" .Or. _cAbas == "08"
        _cAliasCab := "TRBCAB_H"
        _cAliasDet := "TRBDET_H"

        If _cAbas == "08"
            oPanel1H := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2H := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1H := tPanel():New(01,01,"",oTFolder1:aDialogs[8], ,.T.,,,, 100, 100)
            oPanel2H := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[8],,.T.,,,, 500, 200)
        EndIf

        oPanel1H:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2H:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

        // Sintético
        oMarkBRW1H := FWMarkBrowse():New()		   							// Inicializa o Browse
        oMarkBRW1H:SetAlias( _cAliasCab)			   						// Define Alias que será a Base do Browse
        oMarkBRW1H:SetDescription( "08-Total-2o Mes Anterior - Sintético")	// Define o titulo do browse de marcacao
        oMarkBRW1H:SetFields(_aFieldCab)									// Campos para exibição
        oMarkBRW1H:SetOwner(oPanel1H)                                       // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1H:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW1H:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("08-Total-2o Mes Anterior") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1H:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1H:Activate()												// Ativacao da classe

        // Analítico
        oMarkBRW2H := FWMarkBrowse():New()		   							// Inicializa o Browse
        oMarkBRW2H:SetAlias( _cAliasDet)			   						// Define Alias que será a Base do Browse
        oMarkBRW2H:SetDescription( "08-Total-2o Mes Anterior - Analítico")	// Define o titulo do browse de marcacao
        oMarkBRW2H:SetFields(_aFieldDet)									// Campos para exibição
        oMarkBRW2H:SetOwner(oPanel2H)                                       // Define o objeto da tela onde os dados serão exibidos   
        oMarkBRW2H:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW2H:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("H","08") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2H:Activate()												// Ativacao da classe

        If _cAbas == "08"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1H:Align:= CONTROL_ALIGN_TOP , oPanel2H:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf 
    EndIf

    //===============================================================
    // FwMarkBrowser - 09-Total-1o Mes Anterior" = I
    //===============================================================
    If _cAbas == "00" .Or. _cAbas == "09"
        _cAliasCab := "TRBCAB_I"
        _cAliasDet := "TRBDET_I"

        If _cAbas == "09"
            oPanel1I := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2I := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1I := tPanel():New(01,01,"",oTFolder1:aDialogs[9], ,.T.,,,, 100, 100)
            oPanel2I := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[9],,.T.,,,, 500, 200)
        EndIf

        oPanel1I:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2I:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

        // Sintético
        oMarkBRW1I := FWMarkBrowse():New()		   							// Inicializa o Browse
        oMarkBRW1I:SetAlias( _cAliasCab)			   						// Define Alias que será a Base do Browse
        oMarkBRW1I:SetDescription( "09-Total-1o Mes Anterior - Sintético")	// Define o titulo do browse de marcacao
        oMarkBRW1I:SetFields(_aFieldCab)									// Campos para exibição
        oMarkBRW1I:SetOwner(oPanel1I)                                       // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1I:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW1I:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("09-Total-1o Mes Anterior") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1I:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1I:Activate()												// Ativacao da classe

        // Analítico
        oMarkBRW2I := FWMarkBrowse():New()		   							// Inicializa o Browse
        oMarkBRW2I:SetAlias( _cAliasDet)			   						// Define Alias que será a Base do Browse
        oMarkBRW2I:SetDescription( "09-Total-1o Mes Anterior - Analítico")	// Define o titulo do browse de marcacao
        oMarkBRW2I:SetFields(_aFieldDet)									// Campos para exibição
        oMarkBRW2I:SetOwner(oPanel2I)                                       // Define o objeto da tela onde os dados serão exibidos 
        oMarkBRW2I:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW2I:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("I","09") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2I:Activate()												// Ativacao da classe

        If _cAbas == "09"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1I:Align:= CONTROL_ALIGN_TOP , oPanel2I:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf 
    EndIf

    //===============================================================
    // FwMarkBrowser - 10-Total -1o Mes Seguinte" = J
    //===============================================================
    If _cAbas == "00" .Or. _cAbas == "10"
        _cAliasCab := "TRBCAB_J"
        _cAliasDet := "TRBDET_J"

        If _cAbas == "10"
            oPanel1J := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2J := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1J := tPanel():New(01,01,"",oTFolder1:aDialogs[10], ,.T.,,,, 100, 100)
            oPanel2J := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[10],,.T.,,,, 500, 200)
        EndIf

        oPanel1J:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2J:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

        // Sintético
        oMarkBRW1J := FWMarkBrowse():New()		   							// Inicializa o Browse
        oMarkBRW1J:SetAlias( _cAliasCab)			   						// Define Alias que será a Base do Browse
        oMarkBRW1J:SetDescription( "10-Total -1o Mes Seguinte - Sintético")	// Define o titulo do browse de marcacao
        oMarkBRW1J:SetFields(_aFieldCab)								    // Campos para exibição
        oMarkBRW1J:SetOwner(oPanel1J)                                       // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1J:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW1J:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("10-Total -1o Mes Seguinte") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1J:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1J:Activate()									             // Ativacao da classe

        // Analítico
        oMarkBRW2J := FWMarkBrowse():New()		   							// Inicializa o Browse
        oMarkBRW2J:SetAlias( _cAliasDet)			   						// Define Alias que será a Base do Browse
        oMarkBRW2J:SetDescription( "10-Total -1o Mes Seguinte - Analítico")	// Define o titulo do browse de marcacao
        oMarkBRW2J:SetFields(_aFieldDet)								    // Campos para exibição
        oMarkBRW2J:SetOwner(oPanel2J)                                       // Define o objeto da tela onde os dados serão exibidos  
        oMarkBRW2J:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW2J:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("J","10") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2J:Activate()                                                // Ativacao da classe

        If _cAbas == "10"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1J:Align:= CONTROL_ALIGN_TOP , oPanel2J:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf 
    EndIf


    //===============================================================
    // FwMarkBrowser - 11-Total-2o Mes Seguinte" = K 
    //===============================================================
    If _cAbas == "00" .Or. _cAbas == "11"
        _cAliasCab := "TRBCAB_K"
        _cAliasDet := "TRBDET_K"

        If _cAbas == "11"
            oPanel1K := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2K := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1K := tPanel():New(01,01,"",oTFolder1:aDialogs[11], ,.T.,,,, 100, 100)
            oPanel2K := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[11],,.T.,,,, 500, 200)
        EndIf

        oPanel1K:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2K:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (

        // Sintético
        oMarkBRW1K := FWMarkBrowse():New()		   							// Inicializa o Browse
        oMarkBRW1K:SetAlias( _cAliasCab)			   						// Define Alias que será a Base do Browse
        oMarkBRW1K:SetDescription("11-Total-2o Mes Seguinte - Sintético")	// Define o titulo do browse de marcacao
        oMarkBRW1K:SetFields(_aFieldCab)									// Campos para exibição
        oMarkBRW1K:SetOwner(oPanel1K)                                       // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1K:DisableReport()                                           // Desabilita botões padrões
        oMarkBRW1K:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("11-Total-2o Mes Seguinte") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1K:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1K:Activate()												// Ativacao da classe

        // Analítico
        oMarkBRW2K := FWMarkBrowse():New()		   					        // Inicializa o Browse
        oMarkBRW2K:SetAlias( _cAliasDet)			   					    // Define Alias que será a Base do Browse
        oMarkBRW2K:SetDescription("11-Total-2o Mes Seguinte - Analítico")	// Define o titulo do browse de marcacao
        oMarkBRW2K:SetFields(_aFieldDet)									// Campos para exibição
        oMarkBRW2K:SetOwner(oPanel2K)                                       // Define o objeto da tela onde os dados serão exibidos 
        oMarkBRW2K:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW2K:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("K","11") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2K:Activate()										        // Ativacao da classe

        If _cAbas == "11"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1K:Align:= CONTROL_ALIGN_TOP , oPanel2K:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf
    EndIf

    //===============================================================
    // FwMarkBrowser - 12-Total-3o Mes Seguinte" = L
    //===============================================================
    If _cAbas == "00" .Or. _cAbas == "12"
        _cAliasCab := "TRBCAB_L"
        _cAliasDet := "TRBDET_L"

        If _cAbas == "12"
            oPanel1L := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2L := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1L := tPanel():New(01,01,"",oTFolder1:aDialogs[12], ,.T.,,,, 100, 100)
            oPanel2L := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[12],,.T.,,,, 500, 200)
        EndIf

        oPanel1L:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2L:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

        // Sintético
        oMarkBRW1L := FWMarkBrowse():New()		   							// Inicializa o Browse
        oMarkBRW1L:SetAlias( _cAliasCab)			   						// Define Alias que será a Base do Browse
        oMarkBRW1L:SetDescription( "12-Total-3o Mes Seguinte - Sintético")	// Define o titulo do browse de marcacao
        oMarkBRW1L:SetFields(_aFieldCab)									// Campos para exibição
        oMarkBRW1L:SetOwner(oPanel1L)                                       // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1L:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW1L:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("12-Total-3o Mes Seguinte") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1L:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1L:Activate()												// Ativacao da classe

        // Analítico
        oMarkBRW2L := FWMarkBrowse():New()		   						    // Inicializa o Browse
        oMarkBRW2L:SetAlias( _cAliasDet)			   						// Define Alias que será a Base do Browse
        oMarkBRW2L:SetDescription( "12-Total-3o Mes Seguinte - Analítico")	// Define o titulo do browse de marcacao
        oMarkBRW2L:SetFields(_aFieldDet)									// Campos para exibição
        oMarkBRW2L:SetOwner(oPanel2L)                                       // Define o objeto da tela onde os dados serão exibidos 
        oMarkBRW2L:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW2L:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("L","12") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2L:Activate()												// Ativacao da classe

        If _cAbas == "12"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1L:Align:= CONTROL_ALIGN_TOP , oPanel2L:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf
    EndIf

    //===============================================================
    // FwMarkBrowser - 13-Total-4o Mes Seguinte" = M
    //===============================================================
    If _cAbas == "00" .Or. _cAbas == "13"
        _cAliasCab := "TRBCAB_M"
        _cAliasDet := "TRBDET_M"

        If _cAbas == "13"
            oPanel1M := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2M := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1M := tPanel():New(01,01,"",oTFolder1:aDialogs[13], ,.T.,,,, 100, 100)
            oPanel2M := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[13],,.T.,,,, 500, 200)
        EndIf

        oPanel1M:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2M:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

        // Sintético
        oMarkBRW1M := FWMarkBrowse():New()		   							// Inicializa o Browse
        oMarkBRW1M:SetAlias( _cAliasCab)			   						// Define Alias que será a Base do Browse
        oMarkBRW1M:SetDescription( "13-Total-4o Mes Seguinte - Sintético")	// Define o titulo do browse de marcacao
        oMarkBRW1M:SetFields(_aFieldCab)									// Campos para exibição
        oMarkBRW1M:SetOwner(oPanel1M)                                       // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1M:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW1M:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("13-Total-4o Mes Seguinte") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1M:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1M:Activate()												// Ativacao da classe

        // Analítico
        oMarkBRW2M := FWMarkBrowse():New()		   							// Inicializa o Browse
        oMarkBRW2M:SetAlias( _cAliasDet)			   						// Define Alias que será a Base do Browse
        oMarkBRW2M:SetDescription( "13-Total-4o Mes Seguinte - Analítico")	// Define o titulo do browse de marcacao
        oMarkBRW2M:SetFields(_aFieldDet)									// Campos para exibição
        oMarkBRW2M:SetOwner(oPanel2M)                                       // Define o objeto da tela onde os dados serão exibidos  
        oMarkBRW2M:DisableReport()                                          // Desabilita botões padrões
        oMarkBRW2M:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("M","13") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )  
        oMarkBRW2M:Activate()												// Ativacao da classe

        If _cAbas == "13"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1M:Align:= CONTROL_ALIGN_TOP , oPanel2M:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf 
    EndIf

    //===============================================================
    // FwMarkBrowser - 14-Total-Superior ao 4o Mes" = N 
    //===============================================================
    If _cAbas == "00" .Or. _cAbas == "14"
        _cAliasCab := "TRBCAB_N"
        _cAliasDet := "TRBDET_N"

        If _cAbas == "14"
            oPanel1N := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2N := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1N := tPanel():New(01,01,"",oTFolder1:aDialogs[14], ,.T.,,,, 100, 100)
            oPanel2N := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[14],,.T.,,,, 500, 200)
        EndIf

        oPanel1N:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2N:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

        // Sintético
        oMarkBRW1N := FWMarkBrowse():New()		   								// Inicializa o Browse
        oMarkBRW1N:SetAlias( _cAliasCab)			   						    // Define Alias que será a Base do Browse
        oMarkBRW1N:SetDescription( "14-Total-Superior ao 4o Mes - Sintético")	// Define o titulo do browse de marcacao
        oMarkBRW1N:SetFields(_aFieldCab)										// Campos para exibição
        oMarkBRW1N:SetOwner(oPanel1N)                                           // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1N:DisableReport()                                              // Desabilita botões padrões
        oMarkBRW1N:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("14-Total-Superior ao 4o Mes") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1N:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1N:Activate()													// Ativacao da classe

        // Analítico
        oMarkBRW2N := FWMarkBrowse():New()		   							    // Inicializa o Browse
        oMarkBRW2N:SetAlias( _cAliasDet)			   						    // Define Alias que será a Base do Browse
        oMarkBRW2N:SetDescription( "14-Total-Superior ao 4o Mes - Analítico")	// Define o titulo do browse de marcacao
        oMarkBRW2N:SetFields(_aFieldDet)									    // Campos para exibição
        oMarkBRW2N:SetOwner(oPanel2N)                                           // Define o objeto da tela onde os dados serão exibidos  
        oMarkBRW2N:DisableReport()                                              // Desabilita botões padrões
        oMarkBRW2N:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("N","14") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2N:Activate()													// Ativacao da classe

        If _cAbas == "14"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1N:Align:= CONTROL_ALIGN_TOP , oPanel2N:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf 
    EndIf

    //=======================================================================
    // FwMarkBrowser - 15-Total-Emitidas e Vencidas no Mesmo Mes"  = O
    //=======================================================================
    If _cAbas == "00" .Or. _cAbas == "15"
        _cAliasCab := "TRBCAB_O"
        _cAliasDet := "TRBDET_O"

        If _cAbas == "15"
            oPanel1O := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2O := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1O := tPanel():New(01,01,"",oTFolder1:aDialogs[15], ,.T.,,,, 100, 100)
            oPanel2O := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[15],,.T.,,,, 500, 200)
        EndIf

        oPanel1O:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2O:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

        // Sintético
        oMarkBRW1O := FWMarkBrowse():New()		   										    // Inicializa o Browse
        oMarkBRW1O:SetAlias( _cAliasCab)			   										// Define Alias que será a Base do Browse
        oMarkBRW1O:SetDescription("15-Total-Emitidas e Vencidas no Mesmo Mes - Sintético")	// Define o titulo do browse de marcacao
        oMarkBRW1O:SetFields(_aFieldCab)													// Campos para exibição
        oMarkBRW1O:SetOwner(oPanel1O)                                                       // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1O:DisableReport()                                                          // Desabilita botões padrões
        oMarkBRW1O:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("15-Total-Emitidas e Vencidas no Mesmo Mes") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1O:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1O:Activate()																// Ativacao da classe

        // Analítico
        oMarkBRW2O := FWMarkBrowse():New()		   										    // Inicializa o Browse
        oMarkBRW2O:SetAlias( _cAliasDet)			   										// Define Alias que será a Base do Browse
        oMarkBRW2O:SetDescription("15-Total-Emitidas e Vencidas no Mesmo Mes - Analítico")	// Define o titulo do browse de marcacao
        oMarkBRW2O:SetFields(_aFieldDet)													// Campos para exibição
        oMarkBRW2O:SetOwner(oPanel2O)                                                       // Define o objeto da tela onde os dados serão exibidos   
        oMarkBRW2O:DisableReport()                                                          // Desabilita botões padrões
        oMarkBRW2O:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("O","15") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2O:Activate()																// Ativacao da classe

        If _cAbas == "15"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1O:Align:= CONTROL_ALIGN_TOP , oPanel2O:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf
    EndIf

    //===============================================================================================
    // FwMarkBrowser - 16-Total-Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes"  = P
    //===============================================================================================
    If _cAbas == "00" .Or. _cAbas == "16"
        _cAliasCab := "TRBCAB_P"
        _cAliasDet := "TRBDET_P"

        If _cAbas == "16"
            oPanel1P := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2P := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1P := tPanel():New(01,01,"",oTFolder1:aDialogs[16], ,.T.,,,, 100, 100)
            oPanel2P := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[16],,.T.,,,, 500, 200)
        EndIf

        oPanel1P:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2P:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

        // Sintético
        oMarkBRW1P := FWMarkBrowse():New()		   												                    // Inicializa o Browse
        oMarkBRW1P:SetAlias( _cAliasCab)			   											                    // Define Alias que será a Base do Browse
        oMarkBRW1P:SetDescription( "16-Total-Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes - Sintético")	// Define o titulo do browse de marcacao
        oMarkBRW1P:SetFields(_aFieldCab)													 		                // Campos para exibição
        oMarkBRW1P:SetOwner(oPanel1P)                                                                               // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1P:DisableReport()                                                                                  // Desabilita botões padrões
        oMarkBRW1P:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("16-Total-Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1P:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1P:Activate()																		                // Ativacao da classe

        // Analítico
        oMarkBRW2P := FWMarkBrowse():New()		   												                    // Inicializa o Browse
        oMarkBRW2P:SetAlias( _cAliasDet)			   											                    // Define Alias que será a Base do Browse
        oMarkBRW2P:SetDescription( "16-Total-Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes - Analítico")	// Define o titulo do browse de marcacao
        oMarkBRW2P:SetFields(_aFieldDet)													 		                // Campos para exibição
        oMarkBRW2P:SetOwner(oPanel2P)                                                                               // Define o objeto da tela onde os dados serão exibidos    
        oMarkBRW2P:DisableReport()                                                                                  // Desabilita botões padrões
        oMarkBRW2P:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("P","16") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2P:Activate()                                                                                       // Ativacao da classe
                                                                
        If _cAbas == "16"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1P:Align:= CONTROL_ALIGN_TOP , oPanel2P:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf 
    EndIf

    //===============================================================
    // FwMarkBrowser - 17-Vendas do Mes Recebidas no Mes" = Q
    //===============================================================
    If _cAbas == "00" .Or. _cAbas == "17"
        _cAliasCab := "TRBCAB_Q"
        _cAliasDet := "TRBDET_Q"

        If _cAbas == "17"
            oPanel1Q := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2Q := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else  
            oPanel1Q := tPanel():New(01,01,"",oTFolder1:aDialogs[17], ,.T.,,,, 100, 100)
            oPanel2Q := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[17],,.T.,,,, 500, 200)
        EndIf

        oPanel1Q:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2Q:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

        // Sintético
        oMarkBRW1Q := FWMarkBrowse():New()		   									// Inicializa o Browse
        oMarkBRW1Q:SetAlias( _cAliasCab)			   								// Define Alias que será a Base do Browse
        oMarkBRW1Q:SetDescription( "17-Vendas do Mes Recebidas no Mes - Sintético")	// Define o titulo do browse de marcacao
        oMarkBRW1Q:SetFields(_aFieldCab)											// Campos para exibição
        oMarkBRW1Q:SetOwner(oPanel1Q)                                               // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1Q:DisableReport()                                                  // Desabilita botões padrões
        oMarkBRW1Q:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("17-Vendas do Mes Recebidas no Mes") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1Q:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1Q:Activate()														// Ativacao da classe

        // Analítico
        oMarkBRW2Q := FWMarkBrowse():New()		   									// Inicializa o Browse
        oMarkBRW2Q:SetAlias( _cAliasDet)			   								// Define Alias que será a Base do Browse
        oMarkBRW2Q:SetDescription( "17-Vendas do Mes Recebidas no Mes - Analítico")	// Define o titulo do browse de marcacao
        oMarkBRW2Q:SetFields(_aFieldDet)											// Campos para exibição
        oMarkBRW2Q:SetOwner(oPanel2Q)                                               // Define o objeto da tela onde os dados serão exibidos    
        oMarkBRW2Q:DisableReport()                                                  // Desabilita botões padrões
        oMarkBRW2Q:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("Q","17") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2Q:Activate()														// Ativacao da classe

        If _cAbas == "17"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1Q:Align:= CONTROL_ALIGN_TOP , oPanel2Q:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf
    EndIf

    //===============================================================
    // FwMarkBrowser - 18-Devolvidas-RA Compensadas" = R
    //===============================================================
    If _cAbas == "00" .Or. _cAbas == "18"
        _cAliasCab := "TRBCAB_R"
        _cAliasDet := "TRBDET_R"

        If _cAbas == "18"
            oPanel1R := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2R := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1R := tPanel():New(01,01,"",oTFolder1:aDialogs[18], ,.T.,,,, 100, 100)
            oPanel2R := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[18],,.T.,,,, 500, 200)
        EndIf
        
        oPanel1R:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2R:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

        // Sintético
        oMarkBRW1R := FWMarkBrowse():New()		   								// Inicializa o Browse
        oMarkBRW1R:SetAlias( _cAliasCab)			   							// Define Alias que será a Base do Browse
        oMarkBRW1R:SetDescription( "18-Devolvidas-RA Compensadas - Sintético")	// Define o titulo do browse de marcacao
        oMarkBRW1R:SetFields(_aFieldCab)										// Campos para exibição
        oMarkBRW1R:SetOwner(oPanel1R)                                           // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1R:DisableReport()                                              // Desabilita botões padrões
        oMarkBRW1R:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("18-Devolvidas-RA Compensadas") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1R:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1R:Activate()													// Ativacao da classe

        // Analítico
        oMarkBRW2R := FWMarkBrowse():New()		   								// Inicializa o Browse
        oMarkBRW2R:SetAlias( _cAliasDet)			   							// Define Alias que será a Base do Browse
        oMarkBRW2R:SetDescription( "18-Devolvidas-RA Compensadas - Analítico")	// Define o titulo do browse de marcacao
        oMarkBRW2R:SetFields(_aFieldDet)										// Campos para exibição
        oMarkBRW2R:SetOwner(oPanel2R)                                           // Define o objeto da tela onde os dados serão exibidos   
        oMarkBRW2R:DisableReport()                                              // Desabilita botões padrões
        oMarkBRW2R:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("R","18") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2R:Activate()												    // Ativacao da classe

        If _cAbas == "18"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1R:Align:= CONTROL_ALIGN_TOP , oPanel2R:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf 
    EndIf

    //==============================================================================
    // FwMarkBrowser - 19-Devolvidas-NCC Compensadas no M-s(Tipos NF com NCC)" = S
    //==============================================================================
    If _cAbas == "00" .Or. _cAbas == "19"
        _cAliasCab := "TRBCAB_S"
        _cAliasDet := "TRBDET_S"

        If _cAbas == "19"
            oPanel1S := tPanel():New(01,01,"",oTFolder1:aDialogs[1], ,.T.,,,, 100, 100)
            oPanel2S := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[1],,.T.,,,, 500, 200)
        Else
            oPanel1S := tPanel():New(01,01,"",oTFolder1:aDialogs[19], ,.T.,,,, 100, 100)
            oPanel2S := tPanel():New(_aPosObj[2,1]+5, 01,"",oTFolder1:aDialogs[19],,.T.,,,, 500, 200)
        EndIf

        oPanel1S:Align := CONTROL_ALIGN_TOP        // Painel Sintético (topo)
        oPanel2S:Align := CONTROL_ALIGN_ALLCLIENT  // Painel Analítico (preenche o resto)

        // Sintético
        oMarkBRW1S := FWMarkBrowse():New()		   										                // Inicializa o Browse
        oMarkBRW1S:SetAlias( _cAliasCab)			   											        // Define Alias que será a Base do Browse
        oMarkBRW1S:SetDescription( "19-Devolvidas-NCC Compensadas no M-s(Tipos NF com NCC) - Sintético")// Define o titulo do browse de marcacao
        oMarkBRW1S:SetFields(_aFieldCab)													 		    // Campos para exibição
        oMarkBRW1S:SetOwner(oPanel1S)                                                                   // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW1S:DisableReport()                                                                      // Desabilita botões padrões
        oMarkBRW1S:AddButton( "Gera Excel" , {|| Processa( {|| AFIN040E("19-Devolvidas-NCC Compensadas no M-s(Tipos NF com NCC)") } , "Gerando Excel..." , "Aguarde!" ) } ,, 1 )
        oMarkBRW1S:AddButton( "Finalizar" ,  {|| Processa( {|| AFIN040F(_oDlgFin) }, "Finalizando Processo..." ) } ,, 1 )
        oMarkBRW1S:Activate()																		    // Ativacao da classe

        // Analítico
        oMarkBRW2S := FWMarkBrowse():New()		   												        // Inicializa o Browse
        oMarkBRW2S:SetAlias( _cAliasDet)			   											        // Define Alias que será a Base do Browse
        oMarkBRW2S:SetDescription( "19-Devolvidas-NCC Compensadas no M-s(Tipos NF com NCC) - Analítico")// Define o titulo do browse de marcacao
        oMarkBRW2S:SetFields(_aFieldDet)													 		    // Campos para exibição
        oMarkBRW2S:SetOwner(oPanel2S)                                                                   // Define o objeto da tela onde os dados serão exibidos
        oMarkBRW2S:DisableReport()                                                                      // Desabilita botões padrões
        oMarkBRW2S:AddButton( "Pesquisar" ,  {|| Processa( {|| AFIN040I("S","19") } , "Pesquisando..." , "Aguarde!" ) } ,, 4 )
        oMarkBRW2S:Activate()																		   // Ativacao da classe

        If _cAbas == "19"
            _oDlgFin:lMaximized := .T.
            ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1S:Align:= CONTROL_ALIGN_TOP , oPanel2S:Align:= CONTROL_ALIGN_ALLCLIENT)
        EndIf    
    EndIf

    If _cAbas == "00"
        _oDlgFin:lMaximized := .T.
        ACTIVATE MSDIALOG _oDlgFin ON INIT( oTFolder1:Align := CONTROL_ALIGN_ALLCLIENT, oPanel1A:Align:= CONTROL_ALIGN_TOP , oPanel2A:Align:= CONTROL_ALIGN_ALLCLIENT)
    EndIf   															        

    AFIN040K()

Return Nil

/*
===============================================================================================================================
Função-------------: AFIN040A
Autor--------------: Julio de Paula Paz
Data da Criacao----: 11/09/2025
Descrição----------: Cria as tabelas temporárias da rotina
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/
Static Function AFIN040A()

    Local _aStruCab   := {}                     As Array
    Local _aStruDet   := {}                     As Array
    Local cSufixAtual := ""                     As Character
    Local cSufixos    := "ABCDEFGHIJKLMNOPQRS"  As Character
    Local nI          := 0                      As Numeric

    AAdd(_aStruCab ,{"ZCA_VISAO" , "C", Getsx3cache("ZCA_VISAO" ,"X3_TAMANHO"),0})  //  Item Visao
    AAdd(_aStruCab ,{"ZCA_DESVIS", "C", Getsx3cache("ZCA_DESVIS","X3_TAMANHO"),0})  //  Descr.Visao
    AAdd(_aStruCab ,{"ZCA_FILVIS", "C", Getsx3cache("ZCA_FILVIS","X3_TAMANHO"),0})  //  Filial Visao
    AAdd(_aStruCab ,{"ZCA_VALOR" , "N", Getsx3cache("ZCA_VALOR" ,"X3_TAMANHO"),Getsx3cache("ZCA_VALOR","X3_DECIMAL")}) //   Valor Filial
    AAdd(_aStruCab ,{"ZCA_VERSAO", "C", Getsx3cache("ZCA_VERSAO","X3_TAMANHO"),0})  //  Versão
    AAdd(_aStruCab ,{"ZCA_MESANO", "C", Getsx3cache("ZCA_MESANO","X3_TAMANHO"),0})  //  Mês/Ano Emis
    AAdd(_aStruCab ,{"ZCA_DTEMIS", "D", 8, 0})                                      //  Data Emissao dos dados - Geração dos dados do fechamento financeiro
    AAdd(_aStruCab ,{"ZCA_HREMIS", "C", Getsx3cache("ZCA_HREMIS","X3_TAMANHO"),0})  //  Hora Emissao
    AAdd(_aStruCab ,{"ZCA_USUARI", "C", Getsx3cache("ZCA_USUARI","X3_TAMANHO"),0})  //  Usuario Fech            
            
    AAdd(_aStruDet ,{"ZCB_VISAO" , "C", Getsx3cache("ZCB_VISAO" ,"X3_TAMANHO"),0})  //  Item Visao
    AAdd(_aStruDet ,{"ZCB_FILVIS", "C", Getsx3cache("ZCB_FILVIS","X3_TAMANHO"),0})  //  Filial Visao
    AAdd(_aStruDet ,{"ZCB_VERSAO", "C", Getsx3cache("ZCB_VERSAO","X3_TAMANHO"),0})  //  Versão
    AAdd(_aStruDet ,{"ZCB_MESANO", "C", Getsx3cache("ZCB_MESANO","X3_TAMANHO"),0})  //  Mês/Ano Emis
    AAdd(_aStruDet ,{"ZCB_DTEMIS", "D", 8 ,0})                                      //  Data Emissao dos dados - Geração dos dados do fechamento financeiro
    AAdd(_aStruDet ,{"ZCB_HREMIS", "C", Getsx3cache("ZCB_HREMIS","X3_TAMANHO"),0})  //  Hora Emissao
    AAdd(_aStruDet ,{"ZCB_USUARI", "C", Getsx3cache("ZCB_USUARI","X3_TAMANHO"),0})  //  Usuario Fech
    AAdd(_aStruDet ,{"ZCB_NUMTIT", "C", Getsx3cache("ZCB_NUMTIT","X3_TAMANHO"),0})  //  No. Titulo  
    AAdd(_aStruDet ,{"ZCB_PREFIX", "C", Getsx3cache("ZCB_PREFIX","X3_TAMANHO"),0})  //  Prefixo     
    AAdd(_aStruDet ,{"ZCB_PARCEL", "C", Getsx3cache("ZCB_PARCEL","X3_TAMANHO"),0})  //  Parcerla
    AAdd(_aStruDet ,{"ZCB_TIPO"  , "C", Getsx3cache("ZCB_TIPO"  ,"X3_TAMANHO"),0})  //  Tipo
    AAdd(_aStruDet ,{"ZCB_CLIENT", "C", Getsx3cache("ZCB_CLIENT","X3_TAMANHO"),0})  //  Cliente 
    AAdd(_aStruDet ,{"ZCB_LOJA"  , "C", Getsx3cache("ZCB_LOJA"  ,"X3_TAMANHO"),0})  //  Loja
    AAdd(_aStruDet ,{"ZCB_NOMCLI", "C", Getsx3cache("ZCB_NOMCLI","X3_TAMANHO"),0})  //  Nome
    AAdd(_aStruDet ,{"ZCB_VALOR" , "N", Getsx3cache("ZCB_VALOR" ,"X3_TAMANHO"),Getsx3cache("ZCB_VALOR","X3_DECIMAL")}) //  Valor
    AAdd(_aStruDet ,{"ZCB_EMISSA", "D", 8 ,0})                                      //  Emissão do Titulo               

    For nI := 1 To Len(cSufixos)
        cSufixAtual := SubStr(cSufixos, nI, 1)
        AFIN040J( cSufixAtual, _aStruCab, _aStruDet)
    Next nI

Return

/*
===============================================================================================================================
Função-------------: AFIN040b
Autor--------------: Julio de Paula Paz
Data da Criacao----: 11/09/2025
Descrição----------: Gera dados para o Relatório
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/
Static Function AFIN040B(_cGrid,_cFilter)

    Local _aCab1       := {}                             As Array
    Local _aCab2       := {}                             As Array
    Local _aItem1A     := {}                             As Array
    Local _aItem2A     := {}                             As Array
    Local _aItem1B     := {}                             As Array
    Local _aItem2B     := {}                             As Array
    Local _aItem1C     := {}                             As Array
    Local _aItem2C     := {}                             As Array
    Local _aItem1D     := {}                             As Array
    Local _aItem2D     := {}                             As Array
    Local _aItem1E     := {}                             As Array
    Local _aItem2E     := {}                             As Array
    Local _aItem1F     := {}                             As Array
    Local _aItem2F     := {}                             As Array
    Local _aItem1G     := {}                             As Array
    Local _aItem2G     := {}                             As Array
    Local _aItem1H     := {}                             As Array
    Local _aItem2H     := {}                             As Array
    Local _aItem1I     := {}                             As Array
    Local _aItem2I     := {}                             As Array
    Local _aItem1J     := {}                             As Array
    Local _aItem2J     := {}                             As Array
    Local _aItem1K     := {}                             As Array
    Local _aItem2K     := {}                             As Array
    Local _aItem1L     := {}                             As Array
    Local _aItem2L     := {}                             As Array
    Local _aItem1M     := {}                             As Array
    Local _aItem2M     := {}                             As Array
    Local _aItem1N     := {}                             As Array
    Local _aItem2N     := {}                             As Array
    Local _aItem1O     := {}                             As Array
    Local _aItem2O     := {}                             As Array
    Local _aItem1P     := {}                             As Array
    Local _aItem2P     := {}                             As Array
    Local _aItem1Q     := {}                             As Array
    Local _aItem2Q     := {}                             As Array
    Local _aItem1R     := {}                             As Array
    Local _aItem2R     := {}                             As Array
    Local _aItem1S     := {}                             As Array
    Local _aItem2S     := {}                             As Array
    Local _cQry       := ""                             As Character
    Local _cQry2      := ""                             As Character
    Local _cAnoMes    := ""                             As Character
    Local _cDataIni   := ""                             As Character
    Local _cDataVen   := ""                             As Character
    Local _cAnoMesV   := ""                             As Character
    Local _cDataEmi   := ""                             As Character
    Local _cAnoMesE   := ""                             As Character
    Local _cVersao    := ""                             As Character
    Local _cFilTit    := ""                             As Character
    Local _cMesAno    := ""                             As Character
    Local _nTotRCab   := 0                              As Numeric
    Local _nTotRDet   := 0                              As Numeric
    Local _dDataIni   := Ctod("")                       As Date
    Local _dDataVen   := Ctod("")                       As Date
    Local _dDataEmi   := Ctod("")                       As Date
    Local _lTdAbas     := .F.                            As Logical

    Default _cFilter  := ""

    Begin Sequence 

    _cVersao := AFIN040C()
    If Empty(_cVersao)
        _cVersao := "00"    
    Else 
        _cVersao := Soma1(_cVersao)
    EndIf 

    _cAnoMes := SubStr(MV_PAR01,3,4) + SubStr(MV_PAR01,1,2)  
    _cMesAno := SubStr(MV_PAR01,1,2) + "/" + SubStr(MV_PAR01,3,4)  
    If !Empty(MV_PAR03)
        _cFilTit := FORMATIN(Alltrim(MV_PAR03),";")
    Endif 

    AFIN040G(@_aCab1,@_aCab2)   

    If _cAbas == "00" .And. !Empty(_cFilter)
        _cAbas := _cGrid
        _lTdAbas := .T.
    Endif

    ProcRegua(0)

    //============================================
    // 01-Emissão Dentro do Mês = A
    //============================================
    If _cAbas == "00" .Or. _cAbas == "01"
        IncProc("Gerando dados: 01-Emissão Dentro do Mês...")
        //-------- Query Sintético
        _cQry := " SELECT E1_FILIAL FILIAL, SUM(E1_VALOR) VALOR"
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "
        _cQry += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMes + "' "
        _cQry += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' AND E1_ORIGEM='MATA460' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (E1_FILIAL) "
        _cQry += " ORDER BY E1_FILIAL " 

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_VALOR, E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "
        _cQry2 += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMes + "' "
        _cQry2 += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' AND E1_ORIGEM='MATA460' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL " 

        MPSysOpenQuery( _cQry , "QRYCAB_A")
        DBSelectArea("QRYCAB_A")

        Count To _nTotRCab
        QRYCAB_A->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_A")
        DBSelectArea("QRYDET_A")
        
        Count To _nTotRDet
        QRYDET_A->(DbGotop())
        
        ProcRegua(_nTotRCab)

        Do While ! QRYCAB_A->(Eof())
            IncProc("Lendo dados Sintetico -01-Tudo com Emissão Dentro do Mês")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")           // Filial
            ZCA->ZCA_VISAO	 := "01"                    // Item Visao
            ZCA->ZCA_DESVIS := "Emissão Dentro do Mês"	// Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_A->FILIAL	        // Filial Visao // QRYCAB_A->E1_FILIAL
            ZCA->ZCA_VALOR	 := QRYCAB_A->VALOR         // Valor Filial
            ZCA->ZCA_VERSAO := _cVersao	                // Versão
            ZCA->ZCA_MESANO := _cMesAno	                // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()	                // Data Emissao
            ZCA->ZCA_HREMIS := Time()	                // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId 	            // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_A->(DbAppend())
            TRBCAB_A->ZCA_VISAO	:= "01"                        // Item Visao
            TRBCAB_A->ZCA_DESVIS := "Emissão Dentro do Mês"	   // Descr.Visao
            TRBCAB_A->ZCA_FILVIS := QRYCAB_A->FILIAL	       // Filial Visao // QRYCAB_A->E1_FILIAL
            TRBCAB_A->ZCA_VALOR	:= QRYCAB_A->VALOR             // Valor Filial
            TRBCAB_A->ZCA_VERSAO := _cVersao	               // Versão
            TRBCAB_A->ZCA_MESANO := _cMesAno	               // Mês/Ano Emis
            TRBCAB_A->ZCA_DTEMIS := Date()	                   // Data Emissao
            TRBCAB_A->ZCA_HREMIS := Time()	                   // Hora Emissao
            TRBCAB_A->ZCA_USUARI := __cUserId 	               // Usuario Fech

            AAdd(_aItem1A, {"01", "Emissão Dentro do Mês", QRYCAB_A->FILIAL, QRYCAB_A->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})

            QRYCAB_A->(DbSkip())         
        EndDo

        If Len(_aItem1A) > 0
            AAdd(_aCabec,{"01-Emissão no Mês-Sinte",_aCab1})
            AAdd(_aCabec,{"01-Emissão no Mês-Anali",_aCab2})
            AAdd(_aItem , _aItem1A)
        Endif  

        ProcRegua(_nTotRDet) 

        Do While ! QRYDET_A->(Eof())
            IncProc("Lendo dados Analítico -01-Tudo com Emissão Dentro do Mês")
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")	                    //  Filial
            ZCB->ZCB_VISAO	:= "01"                                 //  Item Visao
            ZCB->ZCB_FILVIS := "Emissão Dentro do Mês" 	            //	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao	                            //	Versão
            ZCB->ZCB_MESANO := _cMesAno	                            //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()	                            //	Data Emissao
            ZCB->ZCB_HREMIS := Time()	                            //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId	                        //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_A->E1_NUM                     //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_A->E1_PREFIXO                 //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_A->E1_PARCELA	                //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_A->E1_TIPO   	                //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_A->E1_CLIENTE	                //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_A->E1_LOJA	                //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_A->E1_NOMCLI	                //	Nome
            ZCB->ZCB_VALOR  := QRYDET_A->E1_VALOR	                //	Valor
            ZCB->ZCB_EMISSA := Stod(QRYDET_A->E1_EMISSAO)	        //	Emissão
            ZCB->(MsUnLock()) 

            TRBDET_A->(DbAppend())
            //TRBDET_A->ZCB_FILIAL := xFilial("ZCB")	            //	Filial
            TRBDET_A->ZCB_VISAO	 := "01"                            //	Item Visao
            TRBDET_A->ZCB_FILVIS := "Emissão Dentro do Mês"	        //	Filial Visao
            TRBDET_A->ZCB_VERSAO := _cVersao	                    //	Versão
            TRBDET_A->ZCB_MESANO := _cMesAno	                    //	Mês/Ano Emis
            TRBDET_A->ZCB_DTEMIS := Date()	                        //	Data Emissao
            TRBDET_A->ZCB_HREMIS := Time()	                        //	Hora Emissao
            TRBDET_A->ZCB_USUARI := __cUserId	                    //	Usuario Fech
            TRBDET_A->ZCB_NUMTIT := QRYDET_A->E1_NUM                //	No. Titulo  
            TRBDET_A->ZCB_PREFIX := QRYDET_A->E1_PREFIXO            //	Prefixo     
            TRBDET_A->ZCB_PARCEL := QRYDET_A->E1_PARCELA	        //	Parcerla
            TRBDET_A->ZCB_TIPO   := QRYDET_A->E1_TIPO   	        //	Tipo
            TRBDET_A->ZCB_CLIENT := QRYDET_A->E1_CLIENTE	        //	Cliente 
            TRBDET_A->ZCB_LOJA   := QRYDET_A->E1_LOJA	            //	Loja
            TRBDET_A->ZCB_NOMCLI := QRYDET_A->E1_NOMCLI	            //	Nome
            TRBDET_A->ZCB_VALOR  := QRYDET_A->E1_VALOR	            //	Valor
            TRBDET_A->ZCB_EMISSA := Stod(QRYDET_A->E1_EMISSAO)      //	Emissão

            AAdd(_aItem2A, {"01", "Emissão Dentro do Mês", _cVersao, _cMesAno, Date(), Time(), __cUserId, QRYDET_A->E1_NUM, QRYDET_A->E1_PREFIXO, QRYDET_A->E1_PARCELA, QRYDET_A->E1_TIPO, QRYDET_A->E1_CLIENTE, QRYDET_A->E1_LOJA, QRYDET_A->E1_NOMCLI, QRYDET_A->E1_VALOR, Stod(QRYDET_A->E1_EMISSAO)})
            QRYDET_A->(DbSkip()) 
        EndDo

        If Len(_aItem2A) > 0
            AAdd(_aItem , _aItem2A)
        Endif    
    EndIf  

    //============================================
    // 02-Faturamento Manual no Mês = B
    //============================================
    If _cAbas == "00" .Or. _cAbas == "02"
        IncProc("Gerando dados: 02-Faturamento Manual no Mês")
        //-------- Query Sintético
        _cQry := " SELECT E1_FILIAL, E1_TIPO, SUM(E1_VALOR) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "    
        _cQry += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMes + "' "
        _cQry += " AND ( "
        _cQry += " ( E1_PREFIXO='MAN' AND E1_TIPO IN ('BOL','ICM','NDC') ) OR 
        _cQry += " ( E1_PREFIXO<>'MAN' AND E1_TIPO IN ('ICM') ) 
        _cQry += " ) 
        _cQry += " AND D_E_L_E_T_ = ' '
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY 
        _cQry += " ROLLUP (E1_FILIAL,E1_TIPO) 
        _cQry += " ORDER BY E1_FILIAL 

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_VALOR, E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "    
        _cQry2 += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMes + "' "
        _cQry2 += " AND ( "
        _cQry2 += " ( E1_PREFIXO='MAN' AND E1_TIPO IN ('BOL','ICM','NDC') ) OR "
        _cQry2 += " ( E1_PREFIXO<>'MAN' AND E1_TIPO IN ('ICM') ) "
        _cQry2 += " ) "
        _cQry2 += " AND D_E_L_E_T_ = ' ' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL,E1_NUM "

        MPSysOpenQuery( _cQry , "QRYCAB_B")
        DBSelectArea("QRYCAB_B")
        
        Count To _nTotRCab
        QRYCAB_B->(DbGotop())
        
        MPSysOpenQuery( _cQry2 , "QRYDET_B")
        DBSelectArea("QRYDET_B")
        
        Count To _nTotRDet
        QRYDET_B->(DbGotop())

        Do While ! QRYCAB_B->(Eof())
            IncProc("Lendo dados Sintético - 02-Faturamento Manual no Mês")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                       // Filial
            ZCA->ZCA_VISAO	 := "02"                                // Item Visao
            ZCA->ZCA_DESVIS := "Faturamento Manual no Mês"	        // Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_B->E1_FILIAL	                // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_B->VALOR                     // Valor Filial
            ZCA->ZCA_VERSAO := _cVersao	                            // Versão
            ZCA->ZCA_MESANO := _cMesAno	                            // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()	                            // Data Emissao
            ZCA->ZCA_HREMIS := Time()	                            // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId 	                        // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_B->(DbAppend())
            //TRBCAB_B->ZCA_FILIAL := xFilial("ZCA")                // Filial
            TRBCAB_B->ZCA_VISAO	:= "02"                             // Item Visao
            TRBCAB_B->ZCA_DESVIS := "Faturamento Manual no Mês"	    // Descr.Visao
            TRBCAB_B->ZCA_FILVIS := QRYCAB_B->E1_FILIAL	            // Filial Visao
            TRBCAB_B->ZCA_VALOR	:= QRYCAB_B->VALOR                  // Valor Filial
            TRBCAB_B->ZCA_VERSAO := _cVersao	                    // Versão
            TRBCAB_B->ZCA_MESANO := _cMesAno	                    // Mês/Ano Emis
            TRBCAB_B->ZCA_DTEMIS := Date()	                        // Data Emissao
            TRBCAB_B->ZCA_HREMIS := Time()	                        // Hora Emissao
            TRBCAB_B->ZCA_USUARI := __cUserId 	                    // Usuario Fech

            AAdd(_aItem1B, {"02", "Faturamento Manual no Mês", QRYCAB_B->E1_FILIAL, QRYCAB_B->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_B->(DbSkip())         
        EndDo 

        If Len(_aItem1B) > 0
             AAdd(_aCabec,{"02-Fat. Manual no Mês Sint",_aCab1})
             AAdd(_aCabec,{"02-Fat. Manual no Mês Anal",_aCab2})
             AAdd(_aItem , _aItem1B)
        Endif 

        Do While ! QRYDET_B->(Eof())
            IncProc("Lendo dados Analítico - 02-Faturamento Manual no Mês")
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")	                    //	Filial
            ZCB->ZCB_VISAO	 := "02"                                //	Item Visao
            ZCB->ZCB_FILVIS := "Faturamento Manual no Mês" 	        //	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao	                            //	Versão
            ZCB->ZCB_MESANO := _cMesAno	                            //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()	                            //	Data Emissao
            ZCB->ZCB_HREMIS := Time()	                            //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId	                        //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_B->E1_NUM                     //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_B->E1_PREFIXO                 //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_B->E1_PARCELA	                //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_B->E1_TIPO   	                //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_B->E1_CLIENTE	                //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_B->E1_LOJA	                //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_B->E1_NOMCLI	                //	Nome
            ZCB->ZCB_VALOR  := QRYDET_B->E1_VALOR	                //	Valor
            ZCB->ZCB_EMISSA := Stod(QRYDET_B->E1_EMISSAO)           //	Emissão
            ZCB->(MsUnLock()) 

            TRBDET_B->(DbAppend())
            //TRBDET_B->ZCB_FILIAL := xFilial("ZCB")	            //	Filial
            TRBDET_B->ZCB_VISAO	 := "02"                            //	Item Visao
            TRBDET_B->ZCB_FILVIS := "Faturamento Manual no Mês"	    //	Filial Visao
            TRBDET_B->ZCB_VERSAO := _cVersao	                    //	Versão
            TRBDET_B->ZCB_MESANO := _cMesAno	                    //	Mês/Ano Emis
            TRBDET_B->ZCB_DTEMIS := Date()	                        //	Data Emissao
            TRBDET_B->ZCB_HREMIS := Time()	                        //	Hora Emissao
            TRBDET_B->ZCB_USUARI := __cUserId	                    //	Usuario Fech
            TRBDET_B->ZCB_NUMTIT := QRYDET_B->E1_NUM                //	No. Titulo  
            TRBDET_B->ZCB_PREFIX := QRYDET_B->E1_PREFIXO            //	Prefixo     
            TRBDET_B->ZCB_PARCEL := QRYDET_B->E1_PARCELA	        //	Parcerla
            TRBDET_B->ZCB_TIPO   := QRYDET_B->E1_TIPO   	        //	Tipo
            TRBDET_B->ZCB_CLIENT := QRYDET_B->E1_CLIENTE	        //	Cliente 
            TRBDET_B->ZCB_LOJA   := QRYDET_B->E1_LOJA	            //	Loja
            TRBDET_B->ZCB_NOMCLI := QRYDET_B->E1_NOMCLI	            //	Nome
            TRBDET_B->ZCB_VALOR  := QRYDET_B->E1_VALOR	            //	Valor
            TRBDET_B->ZCB_EMISSA := StoD(QRYDET_B->E1_EMISSAO)      //	Emissão

            AAdd(_aItem2B, {"02", "Faturamento Manual no Mês", _cVersao, _cMesAno, Date(), Time(), __cUserId, QRYDET_B->E1_NUM, QRYDET_B->E1_PREFIXO, QRYDET_B->E1_PARCELA, QRYDET_B->E1_TIPO, QRYDET_B->E1_CLIENTE, QRYDET_B->E1_LOJA, QRYDET_B->E1_NOMCLI, QRYDET_B->E1_VALOR, Stod(QRYDET_B->E1_EMISSAO)})
            QRYDET_B->(DbSkip())  
        EndDo

        If Len(_aItem2B) > 0
             AAdd(_aItem , _aItem2B)
        Endif 
    EndIf

    //============================================
    // 03-Recebimento de Crédito no Mês = C
    //============================================
    If _cAbas == "00" .Or. _cAbas == "03"
        IncProc("Gerando dados: 03-Recebimento de Crédito no Mês")
        //-------- Query Sintético
        _cQry := " SELECT E1_FILIAL, E1_TIPO, SUM(E1_VALOR) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "       
        _cQry += " WHERE ( E1_PREFIXO='MAN' AND E1_TIPO IN 'RC') "
        _cQry += " AND SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMes + "' " 
        _cQry += " AND D_E_L_E_T_ = ' ' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (E1_FILIAL,E1_TIPO) "
        _cQry += " ORDER BY E1_FILIAL " 

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_VALOR, E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "       
        _cQry2 += " WHERE ( E1_PREFIXO='MAN' AND E1_TIPO IN 'RC') "
        _cQry2 += " AND SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMes + "' " 
        _cQry2 += " AND D_E_L_E_T_ = ' ' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL, E1_NUM " 

        MPSysOpenQuery( _cQry , "QRYCAB_C")
        DBSelectArea("QRYCAB_C")
        
        Count To _nTotRCab
        QRYCAB_C->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_C")
        DBSelectArea("QRYDET_C")
        
        Count To _nTotRDet
        QRYDET_C->(DbGotop())

        Do While ! QRYCAB_C->(Eof())
            IncProc("Lendo dados Sintético - 03-Recebimento de Crédito no Mês") 
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                       // Filial
            ZCA->ZCA_VISAO	 := "03"                                // Item Visao
            ZCA->ZCA_DESVIS := "Recebimento de Crédito no Mês"	    // Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_C->E1_FILIAL	                // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_C->VALOR                     // Valor Filial
            ZCA->ZCA_VERSAO := _cVersao	                            // Versão
            ZCA->ZCA_MESANO := _cMesAno	                            // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()	                            // Data Emissao
            ZCA->ZCA_HREMIS := Time()	                            // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId 	                        // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_C->(DbAppend())
            //TRBCAB_C->ZCA_FILIAL := xFilial("ZCA")                        // Filial
            TRBCAB_C->ZCA_VISAO	:= "03"                                     // Item Visao
            TRBCAB_C->ZCA_DESVIS := "Recebimento de Crédito no Mês"	        // Descr.Visao
            TRBCAB_C->ZCA_FILVIS := QRYCAB_C->E1_FILIAL	                    // Filial Visao
            TRBCAB_C->ZCA_VALOR	:= QRYCAB_C->VALOR                          // Valor Filial
            TRBCAB_C->ZCA_VERSAO := _cVersao	                            // Versão
            TRBCAB_C->ZCA_MESANO := _cMesAno	                            // Mês/Ano Emis
            TRBCAB_C->ZCA_DTEMIS := Date()	                                // Data Emissao
            TRBCAB_C->ZCA_HREMIS := Time()	                                // Hora Emissao
            TRBCAB_C->ZCA_USUARI := __cUserId 	                            // Usuario Fech

            AAdd(_aItem1C, {"03", "Recebimento de Crédito no Mês", QRYCAB_C->E1_FILIAL, QRYCAB_C->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_C->(DbSkip())         
        EndDo

        If Len(_aItem1C) > 0
             AAdd(_aCabec,{"03-Recbto Créd no Mês Sint",_aCab1})
             AAdd(_aCabec,{"03-Recbto Créd no Mês Anali",_aCab2})
             AAdd(_aItem , _aItem1C)
        Endif 

        Do While ! QRYDET_C->(Eof())
            IncProc("Lendo dados Analítico - 03-Recebimento de Crédito no Mês")      
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")	                    //	Filial
            ZCB->ZCB_VISAO	 := "03"                                //	Item Visao
            ZCB->ZCB_FILVIS := "Recebimento de Crédito no Mês" 	    //	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao	                            //	Versão
            ZCB->ZCB_MESANO := _cMesAno	                            //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()	                            //	Data Emissao
            ZCB->ZCB_HREMIS := Time()	                            //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId	                        //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_C->E1_NUM                     //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_C->E1_PREFIXO                 //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_C->E1_PARCELA	                //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_C->E1_TIPO   	                //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_C->E1_CLIENTE	                //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_C->E1_LOJA	                //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_C->E1_NOMCLI	                //	Nome
            ZCB->ZCB_VALOR  := QRYDET_C->E1_VALOR	                //	Valor
            ZCB->ZCB_EMISSA := StoD(QRYDET_C->E1_EMISSAO)           //	Emissão
            ZCB->(MsUnLock()) 

            TRBDET_C->(DbAppend())
            //TRBDET_C->ZCB_FILIAL := xFilial("ZCB")	                //	Filial
            TRBDET_C->ZCB_VISAO	 := "03"                                //	Item Visao
            TRBDET_C->ZCB_FILVIS := "03-Recebimento de Crédito no Mês"	//	Filial Visao
            TRBDET_C->ZCB_VERSAO := _cVersao	                        //	Versão
            TRBDET_C->ZCB_MESANO := _cMesAno	                        //	Mês/Ano Emis
            TRBDET_C->ZCB_DTEMIS := Date()	                            //	Data Emissao
            TRBDET_C->ZCB_HREMIS := Time()	                            //	Hora Emissao
            TRBDET_C->ZCB_USUARI := __cUserId	                        //	Usuario Fech
            TRBDET_C->ZCB_NUMTIT := QRYDET_C->E1_NUM                    //	No. Titulo  
            TRBDET_C->ZCB_PREFIX := QRYDET_C->E1_PREFIXO                //	Prefixo     
            TRBDET_C->ZCB_PARCEL := QRYDET_C->E1_PARCELA	            //	Parcerla
            TRBDET_C->ZCB_TIPO   := QRYDET_C->E1_TIPO   	            //	Tipo
            TRBDET_C->ZCB_CLIENT := QRYDET_C->E1_CLIENTE	            //	Cliente 
            TRBDET_C->ZCB_LOJA   := QRYDET_C->E1_LOJA	                //	Loja
            TRBDET_C->ZCB_NOMCLI := QRYDET_C->E1_NOMCLI	                //	Nome
            TRBDET_C->ZCB_VALOR  := QRYDET_C->E1_VALOR	                //	Valor
            TRBDET_C->ZCB_EMISSA := Stod(QRYDET_C->E1_EMISSAO)          //	Emissão

            AAdd(_aItem2C, {"03", "03-Recebimento de Crédito no Mês", _cVersao, _cMesAno, Date(), Time(), __cUserId, QRYDET_C->E1_NUM, QRYDET_C->E1_PREFIXO, QRYDET_C->E1_PARCELA, QRYDET_C->E1_TIPO, QRYDET_C->E1_CLIENTE, QRYDET_C->E1_LOJA, QRYDET_C->E1_NOMCLI, QRYDET_C->E1_VALOR, Stod(QRYDET_C->E1_EMISSAO)})
            QRYDET_C->(DbSkip())  
        EndDo

        If Len(_aItem2C) > 0
             AAdd(_aItem , _aItem2C)
        Endif 
    EndIf

    //============================================
    // 04-Desmembramento no Mês = D
    //============================================
    If _cAbas == "00" .Or. _cAbas == "04"   
        IncProc("Gerando dados: 04-Desmembramento no Mês")
        //-------- Query Sintético
        _cQry := " SELECT E1_FILIAL FILIAL, SUM(E1_VALOR) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "       
        _cQry += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMes + "' " 
        _cQry += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' AND E1_PREFIXO='R' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (E1_FILIAL) " 
        _cQry += " ORDER BY E1_FILIAL "
        
        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_VALOR, E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "       
        _cQry2 += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMes + "' " 
        _cQry2 += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' AND E1_PREFIXO='R' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL, E1_NUM "

        MPSysOpenQuery( _cQry , "QRYCAB_D")
        DBSelectArea("QRYCAB_D")
        
        Count To _nTotRCab
        QRYCAB_D->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_D")
        DBSelectArea("QRYDET_D")
        
        Count To _nTotRDet
        QRYDET_D->(DbGotop())

        Do While ! QRYCAB_D->(Eof())
            IncProc("Lendo dados Sintético - 04-Desmembramento no Mês")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                       // Filial
            ZCA->ZCA_VISAO	 := "04"                                // Item Visao
            ZCA->ZCA_DESVIS := "Desmembramento no Mês"	            // Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_D->FILIAL	                    // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_D->VALOR                     // Valor Filial
            ZCA->ZCA_VERSAO := _cVersao	                            // Versão
            ZCA->ZCA_MESANO := _cMesAno	                            // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()	                            // Data Emissao
            ZCA->ZCA_HREMIS := Time()	                            // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId 	                        // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_D->(DbAppend())
            //TRBCAB_D->ZCA_FILIAL := xFilial("ZCA")                    // Filial
            TRBCAB_D->ZCA_VISAO	:= "04"                                 // Item Visao
            TRBCAB_D->ZCA_DESVIS := "Desmembramento no Mês"	            // Descr.Visao
            TRBCAB_D->ZCA_FILVIS := QRYCAB_D->FILIAL	                // Filial Visao
            TRBCAB_D->ZCA_VALOR	:= QRYCAB_D->VALOR                      // Valor Filial
            TRBCAB_D->ZCA_VERSAO := _cVersao	                        // Versão
            TRBCAB_D->ZCA_MESANO := _cMesAno	                        // Mês/Ano Emis
            TRBCAB_D->ZCA_DTEMIS := Date()	                            // Data Emissao
            TRBCAB_D->ZCA_HREMIS := Time()	                            // Hora Emissao
            TRBCAB_D->ZCA_USUARI := __cUserId 	                        // Usuario Fech

            AAdd(_aItem1D, {"04", "Desmembramento no Mês", QRYCAB_D->FILIAL, QRYCAB_D->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_D->(DbSkip())         
        EndDo

        If Len(_aItem1D) > 0
            AAdd(_aCabec,{"04-Desmembramento Mês Sint",_aCab1})
            AAdd(_aCabec,{"04-Desmembramento Mês Anal",_aCab2})
            AAdd(_aItem , _aItem1D)
        Endif 

        Do While ! QRYDET_D->(Eof())
            IncProc("Lendo dados Analítico - 04-Desmembramento no Mês")
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")	                    //	Filial
            ZCB->ZCB_VISAO	 := "04"                                //	Item Visao
            ZCB->ZCB_FILVIS := "04-Desmembramento no Mês" 	        //	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao	                            //	Versão
            ZCB->ZCB_MESANO := _cMesAno	                            //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()	                            //	Data Emissao
            ZCB->ZCB_HREMIS := Time()	                            //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId	                        //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_D->E1_NUM                     //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_D->E1_PREFIXO                 //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_D->E1_PARCELA	                //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_D->E1_TIPO   	                //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_D->E1_CLIENTE	                //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_D->E1_LOJA	                //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_D->E1_NOMCLI	                //	Nome
            ZCB->ZCB_VALOR  := QRYDET_D->E1_VALOR	                //	Valor
            ZCB->ZCB_EMISSA := Stod(QRYDET_D->E1_EMISSAO)           //	Emissão
            ZCB->(MsUnLock()) 

            TRBDET_D->(DbAppend())
            //TRBDET_D->ZCB_FILIAL := xFilial("ZCB")	            //	Filial
            TRBDET_D->ZCB_VISAO	 := "04"                            //	Item Visao
            TRBDET_D->ZCB_FILVIS := "Desmembramento no Mês"	        //	Filial Visao
            TRBDET_D->ZCB_VERSAO := _cVersao	                    //	Versão
            TRBDET_D->ZCB_MESANO := _cMesAno	                    //	Mês/Ano Emis
            TRBDET_D->ZCB_DTEMIS := Date()	                        //	Data Emissao
            TRBDET_D->ZCB_HREMIS := Time()	                        //	Hora Emissao
            TRBDET_D->ZCB_USUARI := __cUserId	                    //	Usuario Fech
            TRBDET_D->ZCB_NUMTIT := QRYDET_D->E1_NUM                //	No. Titulo  
            TRBDET_D->ZCB_PREFIX := QRYDET_D->E1_PREFIXO            //	Prefixo     
            TRBDET_D->ZCB_PARCEL := QRYDET_D->E1_PARCELA	        //	Parcerla
            TRBDET_D->ZCB_TIPO   := QRYDET_D->E1_TIPO   	        //	Tipo
            TRBDET_D->ZCB_CLIENT := QRYDET_D->E1_CLIENTE	        //	Cliente 
            TRBDET_D->ZCB_LOJA   := QRYDET_D->E1_LOJA	            //	Loja
            TRBDET_D->ZCB_NOMCLI := QRYDET_D->E1_NOMCLI	            //	Nome
            TRBDET_D->ZCB_VALOR  := QRYDET_D->E1_VALOR	            //	Valor
            TRBDET_D->ZCB_EMISSA := Stod(QRYDET_D->E1_EMISSAO)      //	Emissão

            AAdd(_aItem2D, {"04", "Desmembramento no Mês", _cVersao, _cMesAno, Date(), Time(), __cUserId, QRYDET_D->E1_NUM, QRYDET_D->E1_PREFIXO, QRYDET_D->E1_PARCELA, QRYDET_D->E1_TIPO, QRYDET_D->E1_CLIENTE, QRYDET_D->E1_LOJA, QRYDET_D->E1_NOMCLI, QRYDET_D->E1_VALOR, Stod(QRYDET_D->E1_EMISSAO)})
            QRYDET_D->(DbSkip())  
        EndDo

         If Len(_aItem2D) > 0
            AAdd(_aItem , _aItem2D)
        Endif 
    EndIf   

    //============================================
    // 05-Total-Superior 4 meses = E
    //============================================ 
    If _cAbas == "00" .Or. _cAbas == "05"
        IncProc("Gerando dados: 05-Total-Superior 4 meses")
        _cDataIni := "01/" + SubStr(MV_PAR01,1,2) + "/" + SubStr(MV_PAR01,3,4)
        _dDataIni := Ctod(_cDataIni)
        _dDataVen := MonthSum(_dDataIni,1)
        _cDataVen := Dtos(_dDataVen)
        _cAnoMesV := Substr(_cDataVen,1,6)
        _dDataEmi := MonthSub(_dDataIni,4)
        _cDataEmi := Dtos(_dDataEmi)
   
        //-------- Query Sintético
        _cQry := " SELECT FILIAL, SUM(VALOR) VALOR "
        _cQry += " FROM ( "
        _cQry += " SELECT E1_FILIAL FILIAL, SUM(E1_SALDO) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "        
        _cQry += " WHERE SUBSTR(E1_EMISSAO,1,6) < '" + Dtos(_dDataEmi) + "' " 
        _cQry += " AND E1_ORIGEM='MATA460' " 
        _cQry += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY E1_FILIAL "
        _cQry += " ) "
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (FILIAL) "
        _cQry += " ORDER BY FILIAL " 

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_SALDO, E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "        
        _cQry2 += " WHERE SUBSTR(E1_EMISSAO,1,6) < '" + Dtos(_dDataEmi) + "' " 
        _cQry2 += " AND E1_ORIGEM='MATA460' " 
        _cQry2 += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry2 += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
         _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL, E1_NUM "

        MPSysOpenQuery( _cQry , "QRYCAB_E")
        DBSelectArea("QRYCAB_E")
        
        Count To _nTotRCab
        QRYCAB_E->(DbGotop())
        
        MPSysOpenQuery( _cQry2 , "QRYDET_E")
        DBSelectArea("QRYDET_E")
        
        Count To _nTotRDet
        QRYDET_E->(DbGotop())

        Do While ! QRYCAB_E->(Eof())
            IncProc("Lendo dados Sintético - 05-Totalizador-Superior 4 meses")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                       // Filial
            ZCA->ZCA_VISAO	 := "05"                                // Item Visao
            ZCA->ZCA_DESVIS := "05-Total-Superior 4 meses"	        // Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_E->FILIAL	                    // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_E->VALOR                     // Valor Filial
            ZCA->ZCA_VERSAO := _cVersao	                            // Versão
            ZCA->ZCA_MESANO := _cMesAno	                            // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()	                            // Data Emissao
            ZCA->ZCA_HREMIS := Time()	                            // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId 	                        // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_E->(DbAppend())
            //TRBCAB_E->ZCA_FILIAL := xFilial("ZCA")                 // Filial
            TRBCAB_E->ZCA_VISAO	:= "05"                              // Item Visao
            TRBCAB_E->ZCA_DESVIS := "05-Total-Superior 4 meses"	     // Descr.Visao
            TRBCAB_E->ZCA_FILVIS := QRYCAB_E->FILIAL	             // Filial Visao
            TRBCAB_E->ZCA_VALOR	:= QRYCAB_E->VALOR                   //	Valor Filial
            TRBCAB_E->ZCA_VERSAO := _cVersao	                     //	Versão
            TRBCAB_E->ZCA_MESANO := _cMesAno	                     // Mês/Ano Emis
            TRBCAB_E->ZCA_DTEMIS := Date()	                         // Data Emissao
            TRBCAB_E->ZCA_HREMIS := Time()	                         // Hora Emissao
            TRBCAB_E->ZCA_USUARI := __cUserId 	                     // Usuario Fech

            AAdd(_aItem1E, {"05", "05-Total-Superior 4 meses", QRYCAB_E->FILIAL, QRYCAB_E->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_E->(DbSkip())         
        EndDo

        If Len(_aItem1E) > 0
            AAdd(_aCabec,{"05-Total Sup. 4 Meses Sint",_aCab1})
            AAdd(_aCabec,{"05-Total Sup. 4 Meses Anal",_aCab2})
            AAdd(_aItem , _aItem1E)
        Endif 

        Do While ! QRYDET_E->(Eof())
            IncProc("Lendo dados Analítico - 05-Totalizador-Superior 4 meses")
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")	                    //	Filial
            ZCB->ZCB_VISAO	 := "05"                                //	Item Visao
            ZCB->ZCB_FILVIS := "05-Total-Superior 4 meses" 	        //	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao	                            //	Versão
            ZCB->ZCB_MESANO := _cMesAno	                            //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()	                            //	Data Emissao
            ZCB->ZCB_HREMIS := Time()	                            //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId	                        //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_E->E1_NUM                     //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_E->E1_PREFIXO                 //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_E->E1_PARCELA	                //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_E->E1_TIPO   	                //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_E->E1_CLIENTE	                //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_E->E1_LOJA	                //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_E->E1_NOMCLI	                //	Nome
            ZCB->ZCB_VALOR  := QRYDET_E->E1_SALDO	                //	Valor
            ZCB->ZCB_EMISSA := StoD(QRYDET_E->E1_EMISSAO)           //	Emissão
            ZCB->(MsUnLock()) 

            TRBDET_E->(DbAppend())
            //TRBDET_E->ZCB_FILIAL := xFilial("ZCB")	            //	Filial
            TRBDET_E->ZCB_VISAO	:= "05"                             //	Item Visao
            TRBDET_E->ZCB_FILVIS := "05-Total-Superior 4 meses"	    //	Filial Visao
            TRBDET_E->ZCB_VERSAO := _cVersao	                    //	Versão
            TRBDET_E->ZCB_MESANO := _cMesAno	                    //	Mês/Ano Emis
            TRBDET_E->ZCB_DTEMIS := Date()	                        //	Data Emissao
            TRBDET_E->ZCB_HREMIS := Time()	                        //	Hora Emissao
            TRBDET_E->ZCB_USUARI := __cUserId	                    //	Usuario Fech
            TRBDET_E->ZCB_NUMTIT := QRYDET_E->E1_NUM                //	No. Titulo  
            TRBDET_E->ZCB_PREFIX := QRYDET_E->E1_PREFIXO            //	Prefixo     
            TRBDET_E->ZCB_PARCEL := QRYDET_E->E1_PARCELA	        //	Parcerla
            TRBDET_E->ZCB_TIPO   := QRYDET_E->E1_TIPO   	        //	Tipo
            TRBDET_E->ZCB_CLIENT := QRYDET_E->E1_CLIENTE	        //	Cliente 
            TRBDET_E->ZCB_LOJA   := QRYDET_E->E1_LOJA	            //	Loja
            TRBDET_E->ZCB_NOMCLI := QRYDET_E->E1_NOMCLI	            //	Nome
            TRBDET_E->ZCB_VALOR  := QRYDET_E->E1_SALDO	            //	Valor
            TRBDET_E->ZCB_EMISSA := Stod(QRYDET_E->E1_EMISSAO)      //	Emissão

            AAdd(_aItem2E, {"05", "Total-Superior 4 meses", _cVersao, _cMesAno, Date(), Time(), __cUserId, QRYDET_E->E1_NUM, QRYDET_E->E1_PREFIXO, QRYDET_E->E1_PARCELA, QRYDET_E->E1_TIPO, QRYDET_E->E1_CLIENTE, QRYDET_E->E1_LOJA, QRYDET_E->E1_NOMCLI, QRYDET_E->E1_SALDO, Stod(QRYDET_E->E1_EMISSAO)})
            QRYDET_E->(DbSkip())  
        EndDo

        If Len(_aItem2E) > 0
            AAdd(_aItem , _aItem2E)
        Endif 
    EndIf   

    //===================================================
    // 06-Total-Faturamentos do 4º mês anterior = F
    //===================================================
    If _cAbas == "00" .Or. _cAbas == "06"
        IncProc("Gerando dados: 06-Total-Faturamentos do 4º mês anterior")
        _cDataIni := "01/" + SubStr(MV_PAR01,1,2) + "/" + SubStr(MV_PAR01,3,4)
        _dDataIni := Ctod(_cDataIni)
        _dDataVen := MonthSum(_dDataIni,1)
        _cDataVen := Dtos(_dDataVen)
        _cAnoMesV := Substr(_cDataVen,1,6)
        _dDataEmi := MonthSub(_dDataIni,4)
        _cDataEmi := Dtos(_dDataEmi)
        _cAnoMesE := SubStr(_cDataEmi,1,6)
        //-------- Query Sintético
        _cQry := " SELECT FILIAL, SUM(VALOR) VALOR "
        _cQry += " FROM ( "
        _cQry += " SELECT E1_FILIAL FILIAL, SUM(E1_SALDO) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "        
        _cQry += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' " 
        _cQry += " AND E1_ORIGEM='MATA460' " 
        _cQry += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY E1_FILIAL "
        _cQry += " ) "
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (FILIAL) "
        _cQry += " ORDER BY FILIAL " 

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_SALDO,  E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "        
        _cQry2 += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' " 
        _cQry2 += " AND E1_ORIGEM='MATA460' " 
        _cQry2 += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry2 += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL, E1_NUM "

        MPSysOpenQuery( _cQry , "QRYCAB_F")
        DBSelectArea("QRYCAB_F")
        
        Count To _nTotRCab
        QRYCAB_F->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_F")
        DBSelectArea("QRYDET_F")
        
        Count To _nTotRDet
        QRYDET_F->(DbGotop())

        Do While ! QRYCAB_F->(Eof())
            IncProc("Lendo dados Sintético - 06-Totalizador-Faturamentos do 4º mês anterior")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                           // Filial
            ZCA->ZCA_VISAO	 := "06"                                    // Item Visao
            ZCA->ZCA_DESVIS := "Total-Faturamentos do 4º mês anterior"	// Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_F->FILIAL	                        // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_F->VALOR                         //	Valor Filial
            ZCA->ZCA_VERSAO := _cVersao	                                //	Versão
            ZCA->ZCA_MESANO := _cMesAno	                                // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()	                                // Data Emissao
            ZCA->ZCA_HREMIS := Time()	                                // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId 	                            // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_F->(DbAppend())
            //TRBCAB_F->ZCA_FILIAL := xFilial("ZCA")                        // Filial
            TRBCAB_F->ZCA_VISAO	:= "06"                                     // Item Visao
            TRBCAB_F->ZCA_DESVIS := "Total-Faturamentos do 4º mês anterior"	// Descr.Visao
            TRBCAB_F->ZCA_FILVIS := QRYCAB_F->FILIAL	                    // Filial Visao
            TRBCAB_F->ZCA_VALOR	:= QRYCAB_F->VALOR                          // Valor Filial
            TRBCAB_F->ZCA_VERSAO := _cVersao	                            // Versão
            TRBCAB_F->ZCA_MESANO := _cMesAno	                            // Mês/Ano Emis
            TRBCAB_F->ZCA_DTEMIS := Date()	                                // Data Emissao
            TRBCAB_F->ZCA_HREMIS := Time()	                                // Hora Emissao
            TRBCAB_F->ZCA_USUARI := __cUserId 	                            // Usuario Fech

            AAdd(_aItem1F, {"06", "Total-Faturamentos do 4º mês anterior", QRYCAB_F->FILIAL, QRYCAB_F->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_F->(DbSkip())         
        EndDo

        If Len(_aItem1F) > 0
            AAdd(_aCabec,{"06-Tot. Fat. 4º Mês Ant Sint",_aCab1})
            AAdd(_aCabec,{"06-Tot. Fat. 4º Mês Ant Anal",_aCab2})
            AAdd(_aItem,_aItem1F)
        Endif

        Do While ! QRYDET_F->(Eof())
            IncProc("Lendo dados Analítico - 06-Totalizador-Faturamentos do 4º mês anterior")
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")	                        //	Filial
            ZCB->ZCB_VISAO	 := "06"                                    //	Item Visao
            ZCB->ZCB_FILVIS := "Total-Faturamentos do 4º mês anterior" 	//	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao	                                //	Versão
            ZCB->ZCB_MESANO := _cMesAno	                                //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()	                                //	Data Emissao
            ZCB->ZCB_HREMIS := Time()	                                //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId	                            //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_F->E1_NUM                         //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_F->E1_PREFIXO                     //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_F->E1_PARCELA	                    //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_F->E1_TIPO   	                    //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_F->E1_CLIENTE	                    //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_F->E1_LOJA	                    //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_F->E1_NOMCLI	                    //	Nome
            ZCB->ZCB_VALOR  := QRYDET_F->E1_SALDO	                    //	Valor
            ZCB->ZCB_EMISSA := Stod(QRYDET_F->E1_EMISSAO)               //	Emissão
            ZCB->(MsUnLock()) 

            TRBDET_F->(DbAppend())
            //TRBDET_F->ZCB_FILIAL := xFilial("ZCB")	                    //	Filial
            TRBDET_F->ZCB_VISAO	:= "06"                                     //	Item Visao
            TRBDET_F->ZCB_FILVIS := "Total-Faturamentos do 4º mês anterior"	//	Filial Visao
            TRBDET_F->ZCB_VERSAO := _cVersao	                            //	Versão
            TRBDET_F->ZCB_MESANO := _cMesAno	                            //	Mês/Ano Emis
            TRBDET_F->ZCB_DTEMIS := Date()	                                //	Data Emissao
            TRBDET_F->ZCB_HREMIS := Time()	                                //	Hora Emissao
            TRBDET_F->ZCB_USUARI := __cUserId	                            //	Usuario Fech
            TRBDET_F->ZCB_NUMTIT := QRYDET_F->E1_NUM                        //	No. Titulo  
            TRBDET_F->ZCB_PREFIX := QRYDET_F->E1_PREFIXO                    //	Prefixo     
            TRBDET_F->ZCB_PARCEL := QRYDET_F->E1_PARCELA	                //	Parcerla
            TRBDET_F->ZCB_TIPO   := QRYDET_F->E1_TIPO   	                //	Tipo
            TRBDET_F->ZCB_CLIENT := QRYDET_F->E1_CLIENTE	                //	Cliente 
            TRBDET_F->ZCB_LOJA   := QRYDET_F->E1_LOJA	                    //	Loja
            TRBDET_F->ZCB_NOMCLI := QRYDET_F->E1_NOMCLI	                    //	Nome
            TRBDET_F->ZCB_VALOR  := QRYDET_F->E1_SALDO	                    //	Valor
            TRBDET_F->ZCB_EMISSA := StoD(QRYDET_F->E1_EMISSAO)              //	Emissão

            AAdd(_aItem2F, {"06", "Total-Faturamentos do 4º mês anterior", _cVersao, _cMesAno, Date(), Time(), __cUserId, QRYDET_F->E1_NUM, QRYDET_F->E1_PREFIXO, QRYDET_F->E1_PARCELA, QRYDET_F->E1_TIPO, QRYDET_F->E1_CLIENTE, QRYDET_F->E1_LOJA, QRYDET_F->E1_NOMCLI, QRYDET_F->E1_SALDO, StoD(QRYDET_F->E1_EMISSAO)})

            QRYDET_F->(DbSkip())  
        EndDo

        If Len(_aItem2F) > 0
            AAdd(_aItem,_aItem2F)
        Endif    
    EndIf

    //============================================ 
    // 07-Totalizador–3o Mes Anterior = G
    //============================================
    If _cAbas == "00" .Or. _cAbas == "07"    
      IncProc("Gerando dados: 07-Totalizador–3o Mes Anterior")
        _cDataIni := "01/" + SubStr(MV_PAR01,1,2) + "/" + SubStr(MV_PAR01,3,4)
        _dDataIni := Ctod(_cDataIni)
        _dDataVen := MonthSum(_dDataIni,1)
        _cDataVen := Dtos(_dDataVen)
        _cAnoMesV := Substr(_cDataVen,1,6)
        _dDataEmi := MonthSub(_dDataIni,3)
        _cDataEmi := Dtos(_dDataEmi)
        _cAnoMesE := SubStr(_cDataEmi,1,6)

        //-------- Query Sintético
        _cQry := " SELECT FILIAL, SUM(VALOR) VALOR "
        _cQry += " FROM ( "
        _cQry += " SELECT E1_FILIAL FILIAL, SUM(E1_SALDO) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "        
        _cQry += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' " 
        _cQry += " AND E1_ORIGEM='MATA460' " 
        _cQry += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY E1_FILIAL "
        _cQry += " ) "
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (FILIAL) "
        _cQry += " ORDER BY FILIAL " 

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_SALDO,  E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "        
        _cQry2 += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' " 
        _cQry2 += " AND E1_ORIGEM='MATA460' " 
        _cQry2 += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry2 += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL, E1_NUM "

        MPSysOpenQuery( _cQry , "QRYCAB_G")
        DBSelectArea("QRYCAB_G")
        
        Count To _nTotRCab
        QRYCAB_G->(DbGotop())
        
        MPSysOpenQuery( _cQry2 , "QRYDET_G")
        DBSelectArea("QRYDET_G")

        Do While ! QRYCAB_G->(Eof())
            IncProc("Lendo dados Sintético - 07-Totalizador–3o Mes Anterior")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                       // Filial
            ZCA->ZCA_VISAO	 := "07"                                // Item Visao
            ZCA->ZCA_DESVIS := "Total–3o Mes Anterior"	            // Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_G->FILIAL	                    // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_G->VALOR                     //	Valor Filial
            ZCA->ZCA_VERSAO := _cVersao	                            //	Versão
            ZCA->ZCA_MESANO := _cMesAno	                            // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()	                            // Data Emissao
            ZCA->ZCA_HREMIS := Time()	                            // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId 	                        // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_G->(DbAppend())
            //TRBCAB_G->ZCA_FILIAL := xFilial("ZCA")                // Filial
            TRBCAB_G->ZCA_VISAO	:= "07"                             // Item Visao
            TRBCAB_G->ZCA_DESVIS := "Total–3o Mes Anterior"	        // Descr.Visao
            TRBCAB_G->ZCA_FILVIS := QRYCAB_G->FILIAL	            // Filial Visao
            TRBCAB_G->ZCA_VALOR	:= QRYCAB_G->VALOR                  //	Valor Filial
            TRBCAB_G->ZCA_VERSAO := _cVersao	                    //	Versão
            TRBCAB_G->ZCA_MESANO := _cMesAno	                    // Mês/Ano Emis
            TRBCAB_G->ZCA_DTEMIS := Date()	                        // Data Emissao
            TRBCAB_G->ZCA_HREMIS := Time()	                        // Hora Emissao
            TRBCAB_G->ZCA_USUARI := __cUserId 	                    // Usuario Fech

            AAdd(_aItem1G, {"07", "Total–3o Mes Anterior", QRYCAB_G->FILIAL, QRYCAB_G->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_G->(DbSkip())         
        EndDo 

        AAdd(_aItem,_aItem1G)
        AAdd(_aCabec,{"07-Total 3º Mês Ant Sint",_aCab1})
        AAdd(_aCabec,{"07-Total 3º Mês Ant Anal",_aCab2})

        Do While ! QRYDET_G->(Eof())
            IncProc("Lendo dados Analítico - 07-Totalizador–3o Mes Anterior")
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")	                    //	Filial
            ZCB->ZCB_VISAO	 := "07"                                //	Item Visao
            ZCB->ZCB_FILVIS := "Total–3o Mes Anterior" 	            //	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao	                            //	Versão
            ZCB->ZCB_MESANO := _cMesAno	                            //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()	                            //	Data Emissao
            ZCB->ZCB_HREMIS := Time()	                            //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId	                        //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_G->E1_NUM                     //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_G->E1_PREFIXO                 //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_G->E1_PARCELA	                //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_G->E1_TIPO   	                //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_G->E1_CLIENTE	                //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_G->E1_LOJA	                //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_G->E1_NOMCLI	                //	Nome
            ZCB->ZCB_VALOR  := QRYDET_G->E1_SALDO	                //	Valor
            ZCB->ZCB_EMISSA := StoD(QRYDET_G->E1_EMISSAO)           //	Emissão
            ZCB->(MsUnLock()) 

            TRBDET_G->(DbAppend())
            //TRBDET_G->ZCB_FILIAL := xFilial("ZCB")	            //	Filial
            TRBDET_G->ZCB_VISAO	:= "07"                             //	Item Visao
            TRBDET_G->ZCB_FILVIS := "Total–3o Mes Anterior"	        //	Filial Visao
            TRBDET_G->ZCB_VERSAO := _cVersao	                    //	Versão
            TRBDET_G->ZCB_MESANO := _cMesAno	                    //	Mês/Ano Emis
            TRBDET_G->ZCB_DTEMIS := Date()	                        //	Data Emissao
            TRBDET_G->ZCB_HREMIS := Time()	                        //	Hora Emissao
            TRBDET_G->ZCB_USUARI := __cUserId	                    //	Usuario Fech
            TRBDET_G->ZCB_NUMTIT := QRYDET_G->E1_NUM                //	No. Titulo  
            TRBDET_G->ZCB_PREFIX := QRYDET_G->E1_PREFIXO            //	Prefixo     
            TRBDET_G->ZCB_PARCEL := QRYDET_G->E1_PARCELA	        //	Parcerla
            TRBDET_G->ZCB_TIPO   := QRYDET_G->E1_TIPO   	        //	Tipo
            TRBDET_G->ZCB_CLIENT := QRYDET_G->E1_CLIENTE	        //	Cliente 
            TRBDET_G->ZCB_LOJA   := QRYDET_G->E1_LOJA	            //	Loja
            TRBDET_G->ZCB_NOMCLI := QRYDET_G->E1_NOMCLI	            //	Nome
            TRBDET_G->ZCB_VALOR  := QRYDET_G->E1_SALDO	            //	Valor
            TRBDET_G->ZCB_EMISSA := Stod(QRYDET_G->E1_EMISSAO)      //	Emissão

            AAdd(_aItem2G, {"07", "Total–3o Mes Anterior", _cVersao, _cMesAno, Date(), Time(), __cUserId, QRYDET_G->E1_NUM, QRYDET_G->E1_PREFIXO, QRYDET_G->E1_PARCELA, QRYDET_G->E1_TIPO, QRYDET_G->E1_CLIENTE, QRYDET_G->E1_LOJA, QRYDET_G->E1_NOMCLI, QRYDET_G->E1_SALDO, Stod(QRYDET_G->E1_EMISSAO)})

            QRYDET_G->(DbSkip()) 
        EndDo
        AAdd(_aItem,_aItem2G)
    EndIf   

    //============================================
    // 08-Total-2o Mes Anterior = H
    //============================================
    If _cAbas == "00" .Or. _cAbas == "08"
        IncProc("Gerando dados: 08-Totalizador-2o Mes Anterior")
        _cDataIni := "01/" + SubStr(MV_PAR01,1,2) + "/" + SubStr(MV_PAR01,3,4)
        _dDataIni := Ctod(_cDataIni)
        _dDataVen := MonthSum(_dDataIni,1)
        _cDataVen := Dtos(_dDataVen)
        _cAnoMesV := Substr(_cDataVen,1,6)
        _dDataEmi := MonthSub(_dDataIni,2)
        _cDataEmi := Dtos(_dDataEmi)
        _cAnoMesE := SubStr(_cDataEmi,1,6)
        //-------- Query Sintético
        _cQry := " SELECT FILIAL, SUM(VALOR) VALOR "
        _cQry += " FROM ( "
        _cQry += " SELECT E1_FILIAL FILIAL, SUM(E1_SALDO) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry += " AND E1_ORIGEM='MATA460' "  
        _cQry += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY E1_FILIAL "
        _cQry += " ) "
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (FILIAL) "
        _cQry += " ORDER BY FILIAL "  

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_SALDO,  E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry2 += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry2 += " AND E1_ORIGEM='MATA460' "  
        _cQry2 += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry2 += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL, E1_NUM "

        MPSysOpenQuery( _cQry , "QRYCAB_H")
        DBSelectArea("QRYCAB_H")
        
        Count To _nTotRCab
        QRYCAB_H->(DbGotop())
        
        MPSysOpenQuery( _cQry2 , "QRYDET_H")
        DBSelectArea("QRYDET_H")
        
        Count To _nTotRDet
        QRYDET_H->(DbGotop())

        Do While ! QRYCAB_H->(Eof())
            IncProc("Lendo dados Sintético - 08-Totalizador-2o Mes Anterior")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                       // Filial
            ZCA->ZCA_VISAO	 := "08"                                // Item Visao
            ZCA->ZCA_DESVIS := "Total-2o Mes Anterior"              // Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_H->FILIAL                     // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_H->VALOR                     // Valor Filial
            ZCA->ZCA_VERSAO := _cVersao                             // Versão
            ZCA->ZCA_MESANO := _cMesAno                             // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()                               // Data Emissao
            ZCA->ZCA_HREMIS := Time()                               // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId                            // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_H->(DbAppend())
            //TRBCAB_H->ZCA_FILIAL := xFilial("ZCA")                // Filial
            TRBCAB_H->ZCA_VISAO	:= "08"                             // Item Visao
            TRBCAB_H->ZCA_DESVIS := "Total-2o Mes Anterior"         // Descr.Visao
            TRBCAB_H->ZCA_FILVIS := QRYCAB_H->FILIAL                // Filial Visao
            TRBCAB_H->ZCA_VALOR	:= QRYCAB_H->VALOR                  // Valor Filial
            TRBCAB_H->ZCA_VERSAO := _cVersao                        // Versão
            TRBCAB_H->ZCA_MESANO := _cMesAno                        // Mês/Ano Emis
            TRBCAB_H->ZCA_DTEMIS := Date()                          // Data Emissao
            TRBCAB_H->ZCA_HREMIS := Time()                          // Hora Emissao
            TRBCAB_H->ZCA_USUARI := __cUserId                       // Usuario Fech

            AAdd(_aItem1H, {"08", "Total-2o Mes Anterior", QRYCAB_H->FILIAL, QRYCAB_H->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_H->(DbSkip())      
        EndDo

        If Len(_aItem1H) > 0
            AAdd(_aCabec,{"08-Total 2º Mês Ant Sint",_aCab1})
            AAdd(_aCabec,{"08-Total 2º Mês Ant Anal",_aCab2})
            AAdd(_aItem , _aItem1H)
        Endif 

        Do While ! QRYDET_H->(Eof())
            IncProc("Lendo dados Analítico - 08-Totalizador-2o Mes Anterior")
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")                       //	Filial
            ZCB->ZCB_VISAO	 := "08"                                //	Item Visao
            ZCB->ZCB_FILVIS := "Total-2o Mes Anterior"              //	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao                             //	Versão
            ZCB->ZCB_MESANO := _cMesAno                             //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()                               //	Data Emissao
            ZCB->ZCB_HREMIS := Time()                               //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId                            //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_H->E1_NUM                     //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_H->E1_PREFIXO                 //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_H->E1_PARCELA                 //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_H->E1_TIPO                    //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_H->E1_CLIENTE                 //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_H->E1_LOJA                    //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_H->E1_NOMCLI                  //	Nome
            ZCB->ZCB_VALOR  := QRYDET_H->E1_SALDO                   //	Valor
            ZCB->ZCB_EMISSA := Stod(QRYDET_H->E1_EMISSAO)           //	Emissão
            ZCB->(MsUnLock())  

            TRBDET_H->(DbAppend())
            //TRBDET_H->ZCB_FILIAL := xFilial("ZCB")                //	Filial
            TRBDET_H->ZCB_VISAO	 := "08"                            //	Item Visao
            TRBDET_H->ZCB_FILVIS := "Total-2o Mes Anterior"         //	Filial Visao
            TRBDET_H->ZCB_VERSAO := _cVersao                        //	Versão
            TRBDET_H->ZCB_MESANO := _cMesAno                        //	Mês/Ano Emis
            TRBDET_H->ZCB_DTEMIS := Date()                          //	Data Emissao
            TRBDET_H->ZCB_HREMIS := Time()                          //	Hora Emissao
            TRBDET_H->ZCB_USUARI := __cUserId                       //	Usuario Fech
            TRBDET_H->ZCB_NUMTIT := QRYDET_H->E1_NUM                //	No. Titulo  
            TRBDET_H->ZCB_PREFIX := QRYDET_H->E1_PREFIXO            //	Prefixo     
            TRBDET_H->ZCB_PARCEL := QRYDET_H->E1_PARCELA            //	Parcerla
            TRBDET_H->ZCB_TIPO   := QRYDET_H->E1_TIPO               //	Tipo
            TRBDET_H->ZCB_CLIENT := QRYDET_H->E1_CLIENTE            //	Cliente 
            TRBDET_H->ZCB_LOJA   := QRYDET_H->E1_LOJA               //	Loja
            TRBDET_H->ZCB_NOMCLI := QRYDET_H->E1_NOMCLI             //	Nome
            TRBDET_H->ZCB_VALOR  := QRYDET_H->E1_SALDO              //	Valor
            TRBDET_H->ZCB_EMISSA := Stod(QRYDET_H->E1_EMISSAO)      //	Emissão

            AAdd(_aItem2H, {"08", "Total-2o Mes Anterior", _cVersao, _cMesAno, Date(), Time(), __cUserId, QRYDET_H->E1_NUM, QRYDET_H->E1_PREFIXO, QRYDET_H->E1_PARCELA, QRYDET_H->E1_TIPO, QRYDET_H->E1_CLIENTE, QRYDET_H->E1_LOJA, QRYDET_H->E1_NOMCLI, QRYDET_H->E1_SALDO, Stod(QRYDET_H->E1_EMISSAO)})
            QRYDET_H->(DbSkip())  
        EndDo
        AAdd(_aItem,_aItem2H)
    EndIf 

    //============================================
    // 09-Total-1o Mes Anterior = I
    //============================================
    If _cAbas == "00" .Or. _cAbas == "09"
        IncProc("Gerando dados: 09-Totalizador-1o Mes Anterior")
        _cDataIni := "01/" + SubStr(MV_PAR01,1,2) + "/" + SubStr(MV_PAR01,3,4)
        _dDataIni := Ctod(_cDataIni)
        _dDataVen := MonthSum(_dDataIni,1)
        _cDataVen := Dtos(_dDataVen)
        _cAnoMesV := Substr(_cDataVen,1,6)
            
        _dDataEmi := MonthSub(_dDataIni,1)
        _cDataEmi := Dtos(_dDataEmi)
        _cAnoMesE := SubStr(_cDataEmi,1,6)
        //-------- Query Sintético
        _cQry := " SELECT FILIAL, SUM(VALOR) VALOR "
        _cQry += " FROM ( "
        _cQry += " SELECT E1_FILIAL FILIAL, SUM(E1_SALDO) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry += " AND E1_ORIGEM='MATA460' "  
        _cQry += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY E1_FILIAL "
        _cQry += " ) "
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (FILIAL) "
        _cQry += " ORDER BY FILIAL "  

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_SALDO,  E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry2 += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry2 += " AND E1_ORIGEM='MATA460' "  
        _cQry2 += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry2 += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL, E1_NUM "

        MPSysOpenQuery( _cQry , "QRYCAB_I")
        DBSelectArea("QRYCAB_I")
        
        Count To _nTotRCab
        QRYCAB_I->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_I")
        DBSelectArea("QRYDET_I")
        
        Count To _nTotRDet
        QRYDET_I->(DbGotop())

        Do While ! QRYCAB_I->(Eof())
            IncProc("Lendo dados Sintético - 09-Totalizador-1o Mes Anterior") 
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                       // Filial
            ZCA->ZCA_VISAO	 := "09"                                // Item Visao
            ZCA->ZCA_DESVIS := "Total-1o Mes Anterior"              // Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_I->FILIAL                     // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_I->VALOR                     // Valor Filial
            ZCA->ZCA_VERSAO := _cVersao                             // Versão
            ZCA->ZCA_MESANO := _cMesAno                             // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()                               // Data Emissao
            ZCA->ZCA_HREMIS := Time()                               // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId                            // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_I->(DbAppend())
            //TRBCAB_I->ZCA_FILIAL := xFilial("ZCA")                // Filial
            TRBCAB_I->ZCA_VISAO	:= "09"                             // Item Visao
            TRBCAB_I->ZCA_DESVIS := "Total-1o Mes Anterior"         // Descr.Visao
            TRBCAB_I->ZCA_FILVIS := QRYCAB_I->FILIAL                // Filial Visao
            TRBCAB_I->ZCA_VALOR	:= QRYCAB_I->VALOR                  // Valor Filial
            TRBCAB_I->ZCA_VERSAO := _cVersao                        // Versão
            TRBCAB_I->ZCA_MESANO := _cMesAno                        // Mês/Ano Emis
            TRBCAB_I->ZCA_DTEMIS := Date()                          // Data Emissao
            TRBCAB_I->ZCA_HREMIS := Time()                          // Hora Emissao
            TRBCAB_I->ZCA_USUARI := __cUserId                       // Usuario Fech

            AAdd(_aItem1I, {"09", "Total-1o Mes Anterior", QRYCAB_I->FILIAL, QRYCAB_I->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_I->(DbSkip())      
        EndDo 

        If Len(_aItem1I) > 0
            AAdd(_aCabec,{"09-Total 1º Mês Ant Sint",_aCab1})
            AAdd(_aCabec,{"09-Total 1º Mês Ant Anal",_aCab2})
            AAdd(_aItem , _aItem1I)
        Endif 

        Do While ! QRYDET_I->(Eof())
            IncProc("Lendo dados Analítico - 09-Totalizador-1o Mes Anterior") 
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")                       //	Filial
            ZCB->ZCB_VISAO	 := "09"                                //	Item Visao
            ZCB->ZCB_FILVIS := "Total-1o Mes Anterior"              //	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao                             //	Versão
            ZCB->ZCB_MESANO := _cMesAno                             //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()                               //	Data Emissao
            ZCB->ZCB_HREMIS := Time()                               //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId                            //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_I->E1_NUM                     //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_I->E1_PREFIXO                 //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_I->E1_PARCELA                 //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_I->E1_TIPO                    //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_I->E1_CLIENTE                 //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_I->E1_LOJA                    //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_I->E1_NOMCLI                  //	Nome
            ZCB->ZCB_VALOR  := QRYDET_I->E1_SALDO                   //	Valor
            ZCB->ZCB_EMISSA := Stod(QRYDET_I->E1_EMISSAO)           //	Emissão
            ZCB->(MsUnLock())  

            TRBDET_I->(DbAppend())
            //TRBDET_I->ZCB_FILIAL := xFilial("ZCB")                //	Filial
            TRBDET_I->ZCB_VISAO	 := "09"                            //	Item Visao
            TRBDET_I->ZCB_FILVIS := "Total-1o Mes Anterior"         //	Filial Visao
            TRBDET_I->ZCB_VERSAO := _cVersao                        //	Versão
            TRBDET_I->ZCB_MESANO := _cMesAno                        //	Mês/Ano Emis
            TRBDET_I->ZCB_DTEMIS := Date()                          //	Data Emissao
            TRBDET_I->ZCB_HREMIS := Time()                          //	Hora Emissao
            TRBDET_I->ZCB_USUARI := __cUserId                       //	Usuario Fech
            TRBDET_I->ZCB_NUMTIT := QRYDET_I->E1_NUM                //	No. Titulo  
            TRBDET_I->ZCB_PREFIX := QRYDET_I->E1_PREFIXO            //	Prefixo     
            TRBDET_I->ZCB_PARCEL := QRYDET_I->E1_PARCELA            //	Parcerla
            TRBDET_I->ZCB_TIPO   := QRYDET_I->E1_TIPO               //	Tipo
            TRBDET_I->ZCB_CLIENT := QRYDET_I->E1_CLIENTE            //	Cliente 
            TRBDET_I->ZCB_LOJA   := QRYDET_I->E1_LOJA               //	Loja
            TRBDET_I->ZCB_NOMCLI := QRYDET_I->E1_NOMCLI             //	Nome
            TRBDET_I->ZCB_VALOR  := QRYDET_I->E1_SALDO              //	Valor
            TRBDET_I->ZCB_EMISSA := Stod(QRYDET_I->E1_EMISSAO)      //	Emissão

            AAdd(_aItem2I, {"09", "Total-1o Mes Anterior", _cVersao, _cMesAno, Date(), Time(), __cUserId, QRYDET_I->E1_NUM, QRYDET_I->E1_PREFIXO, QRYDET_I->E1_PARCELA, QRYDET_I->E1_TIPO, QRYDET_I->E1_CLIENTE, QRYDET_I->E1_LOJA, QRYDET_I->E1_NOMCLI, QRYDET_I->E1_SALDO, Stod(QRYDET_I->E1_EMISSAO)})
            QRYDET_I->(DbSkip())  
        EndDo
        AAdd(_aItem,_aItem2I) 
    EndIf

    //============================================
    // 10-Total–1o Mes Seguinte = J
    //============================================
    If _cAbas == "00" .Or. _cAbas == "10"
        IncProc("Gerando dados: 10-Total–1o Mes Seguinte")
        _cDataIni := "01/" + SubStr(MV_PAR01,1,2) + "/" + SubStr(MV_PAR01,3,4)
        _dDataIni := Ctod(_cDataIni)
        _dDataVen := MonthSum(_dDataIni,1)
        _cDataVen := Dtos(_dDataVen)
        _cAnoMesV := Substr(_cDataVen,1,6)
        _cDataEmi := Dtos(_dDataIni)
        _cAnoMesE := SubStr(_cDataEmi,1,6)
        //-------- Query Sintético
        _cQry := " SELECT FILIAL, SUM(VALOR) VALOR "
        _cQry += " FROM ( "
        _cQry += " SELECT E1_FILIAL FILIAL, SUM(E1_SALDO) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry += " AND E1_ORIGEM='MATA460' "  
        _cQry += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY E1_FILIAL "
        _cQry += " ) "
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (FILIAL) "
        _cQry += " ORDER BY FILIAL "  

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_SALDO,  E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry2 += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry2 += " AND E1_ORIGEM='MATA460' "  
        _cQry2 += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry2 += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL, E1_NUM "

        MPSysOpenQuery( _cQry , "QRYCAB_J")
        DBSelectArea("QRYCAB_J")
        
        Count To _nTotRCab
        QRYCAB_J->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_J")
        DBSelectArea("QRYDET_J")
        
        Count To _nTotRDet
        QRYDET_J->(DbGotop())

        Do While ! QRYCAB_J->(Eof())
            IncProc("Lendo dados Sintético - 10-Totalizador–1o Mes Seguinte")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                       // Filial
            ZCA->ZCA_VISAO	 := "10"                                // Item Visao
            ZCA->ZCA_DESVIS := "Total–1o Mes Seguinte"              // Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_J->FILIAL                     // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_J->VALOR                     //	Valor Filial
            ZCA->ZCA_VERSAO := _cVersao                             //	Versão
            ZCA->ZCA_MESANO := _cMesAno                             // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()                               // Data Emissao
            ZCA->ZCA_HREMIS := Time()                               // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId                            // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_J->(DbAppend())
            //TRBCAB_J->ZCA_FILIAL := xFilial("ZCA")                // Filial
            TRBCAB_J->ZCA_VISAO	:= "10"                             // Item Visao
            TRBCAB_J->ZCA_DESVIS := "Total–1o Mes Seguinte"         // Descr.Visao
            TRBCAB_J->ZCA_FILVIS := QRYCAB_J->FILIAL                // Filial Visao
            TRBCAB_J->ZCA_VALOR	:= QRYCAB_J->VALOR                  // Valor Filial
            TRBCAB_J->ZCA_VERSAO := _cVersao                        // Versão
            TRBCAB_J->ZCA_MESANO := _cMesAno                        // Mês/Ano Emis
            TRBCAB_J->ZCA_DTEMIS := Date()                          // Data Emissao
            TRBCAB_J->ZCA_HREMIS := Time()                          // Hora Emissao
            TRBCAB_J->ZCA_USUARI := __cUserId                       // Usuario Fech

            AAdd(_aItem1J, {"10", "Total–1o Mes Seguinte", QRYCAB_J->FILIAL, QRYCAB_J->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_J->(DbSkip())      
        EndDo

        If Len(_aItem1J) > 0
            AAdd(_aCabec,{"10-Total 1º Mês Seg. Sint",_aCab1})
            AAdd(_aCabec,{"10-Total 1º Mês Seg. Anal",_aCab2})
            AAdd(_aItem , _aItem1J)
        Endif  

        Do While ! QRYDET_J->(Eof())
            IncProc("Lendo dados Analítico - 10-Totalizador–1o Mes Seguinte")
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")                       //	Filial
            ZCB->ZCB_VISAO	 := "10"                                //	Item Visao
            ZCB->ZCB_FILVIS := "Total–1o Mes Seguinte"              //	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao                             //	Versão
            ZCB->ZCB_MESANO := _cMesAno                             //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()                               //	Data Emissao
            ZCB->ZCB_HREMIS := Time()                               //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId                            //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_J->E1_NUM                     //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_J->E1_PREFIXO                 //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_J->E1_PARCELA                 //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_J->E1_TIPO                    //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_J->E1_CLIENTE                 //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_J->E1_LOJA                    //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_J->E1_NOMCLI                  //	Nome
            ZCB->ZCB_VALOR  := QRYDET_J->E1_SALDO                   //	Valor
            ZCB->ZCB_EMISSA := Stod(QRYDET_J->E1_EMISSAO)           //	Emissão
            ZCB->(MsUnLock())  

            TRBDET_J->(DbAppend())
            //TRBDET_J->ZCB_FILIAL := xFilial("ZCB")                //	Filial
            TRBDET_J->ZCB_VISAO	 := "10"                            //	Item Visao
            TRBDET_J->ZCB_FILVIS := "Total–1o Mes Seguinte"         //	Filial Visao
            TRBDET_J->ZCB_VERSAO := _cVersao                        //	Versão
            TRBDET_J->ZCB_MESANO := _cMesAno                        //	Mês/Ano Emis
            TRBDET_J->ZCB_DTEMIS := Date()                          //	Data Emissao
            TRBDET_J->ZCB_HREMIS := Time()                          //	Hora Emissao
            TRBDET_J->ZCB_USUARI := __cUserId                       //	Usuario Fech
            TRBDET_J->ZCB_NUMTIT := QRYDET_J->E1_NUM                //	No. Titulo  
            TRBDET_J->ZCB_PREFIX := QRYDET_J->E1_PREFIXO            //	Prefixo     
            TRBDET_J->ZCB_PARCEL := QRYDET_J->E1_PARCELA            //	Parcerla
            TRBDET_J->ZCB_TIPO   := QRYDET_J->E1_TIPO               //	Tipo
            TRBDET_J->ZCB_CLIENT := QRYDET_J->E1_CLIENTE            //	Cliente 
            TRBDET_J->ZCB_LOJA   := QRYDET_J->E1_LOJA               //	Loja
            TRBDET_J->ZCB_NOMCLI := QRYDET_J->E1_NOMCLI             //	Nome
            TRBDET_J->ZCB_VALOR  := QRYDET_J->E1_SALDO              //	Valor
            TRBDET_J->ZCB_EMISSA := Stod(QRYDET_J->E1_EMISSAO)      //	Emissão

            AAdd(_aItem2J, {"10", "Total–1o Mes Seguinte", _cVersao, _cMesAno, Date(), Time(), __cUserId, QRYDET_J->E1_NUM, QRYDET_J->E1_PREFIXO, QRYDET_J->E1_PARCELA, QRYDET_J->E1_TIPO, QRYDET_J->E1_CLIENTE, QRYDET_J->E1_LOJA, QRYDET_J->E1_NOMCLI, QRYDET_J->E1_SALDO, Stod(QRYDET_J->E1_EMISSAO)})
            QRYDET_J->(DbSkip())
        EndDo
        AAdd(_aItem,_aItem2J) 
    EndIf

    //============================================
    // 11-Total–2o Mes Seguinte = K 
    //============================================
    If _cAbas == "00" .Or. _cAbas == "11"
        IncProc("Gerando dados: 11-Totalizador–2o Mes Seguinte")
        _cDataIni := "01/" + SubStr(MV_PAR01,1,2) + "/" + SubStr(MV_PAR01,3,4)
        _dDataIni := Ctod(_cDataIni)
        _dDataVen := MonthSum(_dDataIni,2)
        _cDataVen := Dtos(_dDataVen)
        _cAnoMesV := Substr(_cDataVen,1,6)
        _cDataEmi := Dtos(_dDataIni)
        _cAnoMesE := SubStr(_cDataEmi,1,6)
        //-------- Query Sintético
        _cQry := " SELECT FILIAL, SUM(VALOR) VALOR "
        _cQry += " FROM ( "
        _cQry += " SELECT E1_FILIAL FILIAL, SUM(E1_SALDO) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry += " AND E1_ORIGEM='MATA460' "  
        _cQry += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY E1_FILIAL "
        _cQry += " ) "
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (FILIAL) "
        _cQry += " ORDER BY FILIAL "  

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_SALDO,  E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry2 += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry2 += " AND E1_ORIGEM='MATA460' "  
        _cQry2 += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry2 += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL, E1_NUM "

        MPSysOpenQuery( _cQry , "QRYCAB_K")
        DBSelectArea("QRYCAB_K")
        
        Count To _nTotRCab
        QRYCAB_K->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_K")
        DBSelectArea("QRYDET_K")
        
        Count To _nTotRDet
        QRYDET_K->(DbGotop())

        Do While ! QRYCAB_K->(Eof())
            IncProc("Lendo dados Sintético - 11-Totalizador–2o Mes Seguinte")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                       // Filial
            ZCA->ZCA_VISAO	 := "11"                                // Item Visao
            ZCA->ZCA_DESVIS := "Total–2o Mes Seguinte"              // Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_K->FILIAL                     // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_K->VALOR                     // Valor Filial
            ZCA->ZCA_VERSAO := _cVersao                             // Versão
            ZCA->ZCA_MESANO := _cMesAno                             // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()                               // Data Emissao
            ZCA->ZCA_HREMIS := Time()                               // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId                            // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_K->(DbAppend())
            //TRBCAB_K->ZCA_FILIAL := xFilial("ZCA")                // Filial
            TRBCAB_K->ZCA_VISAO	:= "11"                             // Item Visao
            TRBCAB_K->ZCA_DESVIS := "Total–2o Mes Seguinte"         // Descr.Visao
            TRBCAB_K->ZCA_FILVIS := QRYCAB_K->FILIAL                // Filial Visao
            TRBCAB_K->ZCA_VALOR	:= QRYCAB_K->VALOR                  //	Valor Filial
            TRBCAB_K->ZCA_VERSAO := _cVersao                        //	Versão
            TRBCAB_K->ZCA_MESANO := _cMesAno                        // Mês/Ano Emis
            TRBCAB_K->ZCA_DTEMIS := Date()                          // Data Emissao
            TRBCAB_K->ZCA_HREMIS := Time()                          // Hora Emissao
            TRBCAB_K->ZCA_USUARI := __cUserId                       // Usuario Fech

            AAdd(_aItem1K, {"11", "Total–2o Mes Seguinte", QRYCAB_K->FILIAL, QRYCAB_K->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_K->(DbSkip())      
        EndDo

        If Len(_aItem1K) > 0
            AAdd(_aCabec,{"11-Total 2º Mês Seg Sint",_aCab1})
            AAdd(_aCabec,{"11-Total 2º Mês Seg Anal",_aCab2})
            AAdd(_aItem , _aItem1K)
        Endif

        Do While ! QRYDET_K->(Eof())
            IncProc("Lendo dados Analítico - 11-Totalizador–2o Mes Seguinte")
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")                       //	Filial
            ZCB->ZCB_VISAO	 := "11"                                //	Item Visao
            ZCB->ZCB_FILVIS := "Total–2o Mes Seguinte"              //	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao                             //	Versão
            ZCB->ZCB_MESANO := _cMesAno                             //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()                               //	Data Emissao
            ZCB->ZCB_HREMIS := Time()                               //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId                            //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_K->E1_NUM                     //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_K->E1_PREFIXO                 //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_K->E1_PARCELA                 //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_K->E1_TIPO                    //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_K->E1_CLIENTE                 //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_K->E1_LOJA                    //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_K->E1_NOMCLI                  //	Nome
            ZCB->ZCB_VALOR  := QRYDET_K->E1_SALDO                   //	Valor
            ZCB->ZCB_EMISSA := Stod(QRYDET_K->E1_EMISSAO)           //	Emissão
            ZCB->(MsUnLock())  

            TRBDET_K->(DbAppend())
            //TRBDET_K->ZCB_FILIAL := xFilial("ZCB")                //	Filial
            TRBDET_K->ZCB_VISAO	 := "11"                            //	Item Visao
            TRBDET_K->ZCB_FILVIS := "Total–2o Mes Seguinte"         //	Filial Visao
            TRBDET_K->ZCB_VERSAO := _cVersao                        //	Versão
            TRBDET_K->ZCB_MESANO := _cMesAno                        //	Mês/Ano Emis
            TRBDET_K->ZCB_DTEMIS := Date()                          //	Data Emissao
            TRBDET_K->ZCB_HREMIS := Time()                          //	Hora Emissao
            TRBDET_K->ZCB_USUARI := __cUserId                       //	Usuario Fech
            TRBDET_K->ZCB_NUMTIT := QRYDET_K->E1_NUM                //	No. Titulo  
            TRBDET_K->ZCB_PREFIX := QRYDET_K->E1_PREFIXO            //	Prefixo     
            TRBDET_K->ZCB_PARCEL := QRYDET_K->E1_PARCELA            //	Parcerla
            TRBDET_K->ZCB_TIPO   := QRYDET_K->E1_TIPO               //	Tipo
            TRBDET_K->ZCB_CLIENT := QRYDET_K->E1_CLIENTE            //	Cliente 
            TRBDET_K->ZCB_LOJA   := QRYDET_K->E1_LOJA               //	Loja
            TRBDET_K->ZCB_NOMCLI := QRYDET_K->E1_NOMCLI             //	Nome
            TRBDET_K->ZCB_VALOR  := QRYDET_K->E1_SALDO              //	Valor
            TRBDET_K->ZCB_EMISSA := Stod(QRYDET_K->E1_EMISSAO)      //	Emissão

            AAdd(_aItem2K, {"11", "Total–2o Mes Seguinte", _cVersao, _cMesAno, Date(), Time(), __cUserId, QRYDET_K->E1_NUM, QRYDET_K->E1_PREFIXO, QRYDET_K->E1_PARCELA, QRYDET_K->E1_TIPO, QRYDET_K->E1_CLIENTE, QRYDET_K->E1_LOJA, QRYDET_K->E1_NOMCLI, QRYDET_K->E1_SALDO, Stod(QRYDET_K->E1_EMISSAO)})
            QRYDET_K->(DbSkip())  
        EndDo
        AAdd(_aItem,_aItem2K)
    EndIf

    //============================================
    // 12-Total–3o Mes Seguinte = L
    //============================================
    If _cAbas == "00" .Or. _cAbas == "12"
        IncProc("Gerando dados: 12-Totalizador–3o Mes Seguinte")
         _cDataIni := "01/" + SubStr(MV_PAR01,1,2) + "/" + SubStr(MV_PAR01,3,4)
        _dDataIni := Ctod(_cDataIni)
        _dDataVen := MonthSum(_dDataIni,3)
        _cDataVen := Dtos(_dDataVen)
        _cAnoMesV := Substr(_cDataVen,1,6)
        _cDataEmi := Dtos(_dDataIni)
        _cAnoMesE := SubStr(_cDataEmi,1,6)
        //-------- Query Sintético
        _cQry := " SELECT FILIAL, SUM(VALOR) VALOR "
        _cQry += " FROM ( "
        _cQry += " SELECT E1_FILIAL FILIAL, SUM(E1_SALDO) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry += " AND E1_ORIGEM='MATA460' "  
        _cQry += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY E1_FILIAL "
        _cQry += " ) "
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (FILIAL) "
        _cQry += " ORDER BY FILIAL "  

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_SALDO,  E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry2 += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry2 += " AND E1_ORIGEM='MATA460' "  
        _cQry2 += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry2 += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL, E1_NUM "

        MPSysOpenQuery( _cQry , "QRYCAB_L")
        DBSelectArea("QRYCAB_L")
        
        Count To _nTotRCab
        QRYCAB_L->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_L")
        DBSelectArea("QRYDET_L")
        
        Count To _nTotRDet
        QRYDET_L->(DbGotop())

        Do While ! QRYCAB_L->(Eof())
            IncProc("Lendo dados Sintético - 12-Totalizador–3o Mes Seguinte")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                       // Filial
            ZCA->ZCA_VISAO	 := "12"                                // Item Visao
            ZCA->ZCA_DESVIS := "Total–3o Mes Seguinte"              // Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_L->FILIAL                     // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_L->VALOR                     // Valor Filial
            ZCA->ZCA_VERSAO := _cVersao                             // Versão
            ZCA->ZCA_MESANO := _cMesAno                             // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()                               // Data Emissao
            ZCA->ZCA_HREMIS := Time()                               // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId                            // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_L->(DbAppend())
            //TRBCAB_L->ZCA_FILIAL := xFilial("ZCA")                // Filial
            TRBCAB_L->ZCA_VISAO	:= "12"                             // Item Visao
            TRBCAB_L->ZCA_DESVIS := "Total–3o Mes Seguinte"         // Descr.Visao
            TRBCAB_L->ZCA_FILVIS := QRYCAB_L->FILIAL                // Filial Visao
            TRBCAB_L->ZCA_VALOR	:= QRYCAB_L->VALOR                  // Valor Filial
            TRBCAB_L->ZCA_VERSAO := _cVersao                        // Versão
            TRBCAB_L->ZCA_MESANO := _cMesAno                        // Mês/Ano Emis
            TRBCAB_L->ZCA_DTEMIS := Date()                          // Data Emissao
            TRBCAB_L->ZCA_HREMIS := Time()                          // Hora Emissao
            TRBCAB_L->ZCA_USUARI := __cUserId                       // Usuario Fech

            AAdd(_aItem1L, {"12", "Total–3o Mes Seguinte", QRYCAB_L->FILIAL, QRYCAB_L->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_L->(DbSkip())      
        EndDo

        If Len(_aItem1L) > 0
            AAdd(_aCabec,{"12-Total 3º Mês Seg Sint",_aCab1})
            AAdd(_aCabec,{"12-Total 3º Mês Seg Anal",_aCab2})
            AAdd(_aItem , _aItem1L)
        Endif

        Do While ! QRYDET_L->(Eof())
            IncProc("Lendo dados Analítico - 12-Totalizador–3o Mes Seguinte")
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")                       //	Filial
            ZCB->ZCB_VISAO	 := "12"                                //	Item Visao
            ZCB->ZCB_FILVIS := "Total–3o Mes Seguinte"              //	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao                             //	Versão
            ZCB->ZCB_MESANO := _cMesAno                             //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()                               //	Data Emissao
            ZCB->ZCB_HREMIS := Time()                               //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId                            //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_L->E1_NUM                     //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_L->E1_PREFIXO                 //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_L->E1_PARCELA                 //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_L->E1_TIPO                    //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_L->E1_CLIENTE                 //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_L->E1_LOJA                    //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_L->E1_NOMCLI                  //	Nome
            ZCB->ZCB_VALOR  := QRYDET_L->E1_SALDO                   //	Valor
            ZCB->ZCB_EMISSA := Stod(QRYDET_L->E1_EMISSAO)           //	Emissão
            ZCB->(MsUnLock())  

            TRBDET_L->(DbAppend())
            //TRBDET_L->ZCB_FILIAL := xFilial("ZCB")                //	Filial
            TRBDET_L->ZCB_VISAO	 := "12"                            //	Item Visao
            TRBDET_L->ZCB_FILVIS := "Total–3o Mes Seguinte"         //	Filial Visao
            TRBDET_L->ZCB_VERSAO := _cVersao                        //	Versão
            TRBDET_L->ZCB_MESANO := _cMesAno                        //	Mês/Ano Emis
            TRBDET_L->ZCB_DTEMIS := Date()                          //	Data Emissao
            TRBDET_L->ZCB_HREMIS := Time()                          //	Hora Emissao
            TRBDET_L->ZCB_USUARI := __cUserId                       //	Usuario Fech
            TRBDET_L->ZCB_NUMTIT := QRYDET_L->E1_NUM                //	No. Titulo  
            TRBDET_L->ZCB_PREFIX := QRYDET_L->E1_PREFIXO            //	Prefixo     
            TRBDET_L->ZCB_PARCEL := QRYDET_L->E1_PARCELA            //	Parcerla
            TRBDET_L->ZCB_TIPO   := QRYDET_L->E1_TIPO               //	Tipo
            TRBDET_L->ZCB_CLIENT := QRYDET_L->E1_CLIENTE            //	Cliente 
            TRBDET_L->ZCB_LOJA   := QRYDET_L->E1_LOJA               //	Loja
            TRBDET_L->ZCB_NOMCLI := QRYDET_L->E1_NOMCLI             //	Nome
            TRBDET_L->ZCB_VALOR  := QRYDET_L->E1_SALDO              //	Valor
            TRBDET_L->ZCB_EMISSA := Stod(QRYDET_L->E1_EMISSAO)      //	Emissão

            AAdd(_aItem2L, {"12", "Total–3o Mes Seguinte", _cVersao, _cMesAno, Date(), Time(), __cUserId, QRYDET_L->E1_NUM, QRYDET_L->E1_PREFIXO, QRYDET_L->E1_PARCELA, QRYDET_L->E1_TIPO, QRYDET_L->E1_CLIENTE, QRYDET_L->E1_LOJA, QRYDET_L->E1_NOMCLI, QRYDET_L->E1_SALDO, Stod(QRYDET_L->E1_EMISSAO)})
            QRYDET_L->(DbSkip())  
        EndDo
        AAdd(_aItem,_aItem2L)   
    EndIf

    //============================================
    // 13-Total–4o Mes Seguinte = M
    //============================================
    If _cAbas == "00" .Or. _cAbas == "13"
         IncProc("Gerando dados: 13-Totalizador–4o Mes Seguinte")
        _cDataIni := "01/" + SubStr(MV_PAR01,1,2) + "/" + SubStr(MV_PAR01,3,4)
        _dDataIni := Ctod(_cDataIni)
        _dDataVen := MonthSum(_dDataIni,4)
        _cDataVen := Dtos(_dDataVen)
        _cAnoMesV := Substr(_cDataVen,1,6)
        _cDataEmi := Dtos(_dDataIni)
        _cAnoMesE := SubStr(_cDataEmi,1,6)
        //-------- Query Sintético
        _cQry := " SELECT FILIAL, SUM(VALOR) VALOR "
        _cQry += " FROM ( "
        _cQry += " SELECT E1_FILIAL FILIAL, SUM(E1_SALDO) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry += " AND E1_ORIGEM='MATA460' "  
        _cQry += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY E1_FILIAL "
        _cQry += " ) "
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (FILIAL) "
        _cQry += " ORDER BY FILIAL "  

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_SALDO,  E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry2 += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry2 += " AND E1_ORIGEM='MATA460' "  
        _cQry2 += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry2 += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL, E1_NUM "

        MPSysOpenQuery( _cQry , "QRYCAB_M")
        DBSelectArea("QRYCAB_M")
        
        Count To _nTotRCab
        QRYCAB_M->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_M")
        DBSelectArea("QRYDET_M")
        
        Count To _nTotRDet
        QRYDET_M->(DbGotop())

        Do While ! QRYCAB_M->(Eof())
            IncProc("Lendo dados Sintético - 13-Totalizador–4o Mes Seguinte")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                       // Filial
            ZCA->ZCA_VISAO	 := "13"                                // Item Visao
            ZCA->ZCA_DESVIS := "Total–4o Mes Seguinte"              // Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_M->FILIAL                     // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_M->VALOR                     // Valor Filial
            ZCA->ZCA_VERSAO := _cVersao                             // Versão
            ZCA->ZCA_MESANO := _cMesAno                             // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()                               // Data Emissao
            ZCA->ZCA_HREMIS := Time()                               // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId                            // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_M->(DbAppend())
            //TRBCAB_M->ZCA_FILIAL := xFilial("ZCA")                // Filial
            TRBCAB_M->ZCA_VISAO	:= "13"                             // Item Visao
            TRBCAB_M->ZCA_DESVIS := "Total–4o Mes Seguinte"         // Descr.Visao
            TRBCAB_M->ZCA_FILVIS := QRYCAB_M->FILIAL                // Filial Visao
            TRBCAB_M->ZCA_VALOR	:= QRYCAB_M->VALOR                  // Valor Filial
            TRBCAB_M->ZCA_VERSAO := _cVersao                        // Versão
            TRBCAB_M->ZCA_MESANO := _cMesAno                        // Mês/Ano Emis
            TRBCAB_M->ZCA_DTEMIS := Date()                          // Data Emissao
            TRBCAB_M->ZCA_HREMIS := Time()                          // Hora Emissao
            TRBCAB_M->ZCA_USUARI := __cUserId                       // Usuario Fech

            AAdd(_aItem1M, {"13", "Total–4o Mes Seguinte", QRYCAB_M->FILIAL, QRYCAB_M->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_M->(DbSkip())      
        EndDo

        If Len(_aItem1M) > 0
            AAdd(_aCabec,{"13-Total 4º Mês Seg Sint",_aCab1})
            AAdd(_aCabec,{"13-Total 4º Mês Seg Anal",_aCab2})
            AAdd(_aItem,_aItem1M)
        Endif       

        Do While ! QRYDET_M->(Eof())
            IncProc("Lendo dados Analítico - 13-Totalizador–4o Mes Seguinte")
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")                       //	Filial
            ZCB->ZCB_VISAO	 := "13"                                //	Item Visao
            ZCB->ZCB_FILVIS := "Total–4o Mes Seguinte"              //	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao                             //	Versão
            ZCB->ZCB_MESANO := _cMesAno                             //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()                               //	Data Emissao
            ZCB->ZCB_HREMIS := Time()                               //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId                            //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_M->E1_NUM                     //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_M->E1_PREFIXO                 //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_M->E1_PARCELA                 //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_M->E1_TIPO                    //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_M->E1_CLIENTE                 //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_M->E1_LOJA                    //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_M->E1_NOMCLI                  //	Nome
            ZCB->ZCB_VALOR  := QRYDET_M->E1_SALDO                   //	Valor
            ZCB->ZCB_EMISSA := Stod(QRYDET_M->E1_EMISSAO)           //	Emissão
            ZCB->(MsUnLock())  

            TRBDET_M->(DbAppend())
            //TRBDET_M->ZCB_FILIAL := xFilial("ZCB")                //	Filial
            TRBDET_M->ZCB_VISAO	 := "13"                            //	Item Visao
            TRBDET_M->ZCB_FILVIS := "Total–4o Mes Seguinte"         //	Filial Visao
            TRBDET_M->ZCB_VERSAO := _cVersao                        //	Versão
            TRBDET_M->ZCB_MESANO := _cMesAno                        //	Mês/Ano Emis
            TRBDET_M->ZCB_DTEMIS := Date()                          //	Data Emissao
            TRBDET_M->ZCB_HREMIS := Time()                          //	Hora Emissao
            TRBDET_M->ZCB_USUARI := __cUserId                       //	Usuario Fech
            TRBDET_M->ZCB_NUMTIT := QRYDET_M->E1_NUM                //	No. Titulo  
            TRBDET_M->ZCB_PREFIX := QRYDET_M->E1_PREFIXO            //	Prefixo     
            TRBDET_M->ZCB_PARCEL := QRYDET_M->E1_PARCELA            //	Parcerla
            TRBDET_M->ZCB_TIPO   := QRYDET_M->E1_TIPO               //	Tipo
            TRBDET_M->ZCB_CLIENT := QRYDET_M->E1_CLIENTE            //	Cliente 
            TRBDET_M->ZCB_LOJA   := QRYDET_M->E1_LOJA               //	Loja
            TRBDET_M->ZCB_NOMCLI := QRYDET_M->E1_NOMCLI             //	Nome
            TRBDET_M->ZCB_VALOR  := QRYDET_M->E1_SALDO              //	Valor
            TRBDET_M->ZCB_EMISSA := Stod(QRYDET_M->E1_EMISSAO)      //	Emissão

            AAdd(_aItem2M, {"13", "Total–4o Mes Seguinte", _cVersao, _cMesAno, Date(), Time(), __cUserId, QRYDET_M->E1_NUM, QRYDET_M->E1_PREFIXO, QRYDET_M->E1_PARCELA, QRYDET_M->E1_TIPO, QRYDET_M->E1_CLIENTE, QRYDET_M->E1_LOJA, QRYDET_M->E1_NOMCLI, QRYDET_M->E1_SALDO, Stod(QRYDET_M->E1_EMISSAO)})
            QRYDET_M->(DbSkip())  
        EndDo

        If Len(_aItem2M) > 0
            AAdd(_aItem,_aItem2M)
        Endif  
    EndIf

    //============================================
    // 14-Total–Superior ao 4o Mes" = N 
    //============================================
    If _cAbas == "00" .Or. _cAbas == "14"
        IncProc("Gerando dados: 14-Totalizador–Superior ao 4o Mes")
        _cDataIni := "01/" + SubStr(MV_PAR01,1,2) + "/" + SubStr(MV_PAR01,3,4)
        _dDataIni := Ctod(_cDataIni)
        _dDataVen := MonthSum(_dDataIni,5) // Para termos o ultimo dia do mês. Somamos um mês a mais.
        _dDataVen := _dDataVen - 1         // Subtraimos 1 dia para obtermos o ultimo dia do mês Anterior.
        _cDataVen := Dtos(_dDataVen)
        _cDataEmi := Dtos(_dDataIni)
        _cAnoMesE := SubStr(_cDataEmi,1,6)
        //-------- Query Sintético
        _cQry := " SELECT FILIAL, SUM(VALOR) VALOR "
        _cQry += " FROM ( "
        _cQry += " SELECT E1_FILIAL FILIAL, SUM(E1_SALDO) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry += " AND E1_ORIGEM='MATA460' "  
        _cQry += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY E1_FILIAL "
        _cQry += " ) "
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (FILIAL) "
        _cQry += " ORDER BY FILIAL "  

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_SALDO,  E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry2 += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry2 += " AND E1_ORIGEM='MATA460' "  
        _cQry2 += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry2 += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL, E1_NUM "

        MPSysOpenQuery( _cQry , "QRYCAB_N")
        DBSelectArea("QRYCAB_N")
        
        Count To _nTotRCab
        QRYCAB_N->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_N")
        DBSelectArea("QRYDET_N")
        
        Count To _nTotRDet
        QRYDET_N->(DbGotop())

        Do While ! QRYCAB_N->(Eof())
            IncProc("Lendo dados Sintético - 14-Totalizador–Superior ao 4o Mes")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                       // Filial
            ZCA->ZCA_VISAO	 := "14"                                // Item Visao
            ZCA->ZCA_DESVIS := "Total–Superior ao 4o Mes"           // Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_N->FILIAL                     // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_N->VALOR                     // Valor Filial
            ZCA->ZCA_VERSAO := _cVersao                             // Versão
            ZCA->ZCA_MESANO := _cMesAno                             // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()                               // Data Emissao
            ZCA->ZCA_HREMIS := Time()                               // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId                            // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_N->(DbAppend())
            //TRBCAB_N->ZCA_FILIAL := xFilial("ZCA")                // Filial
            TRBCAB_N->ZCA_VISAO	:= "14"                             // Item Visao
            TRBCAB_N->ZCA_DESVIS := "Total–Superior ao 4o Mes"      // Descr.Visao
            TRBCAB_N->ZCA_FILVIS := QRYCAB_N->FILIAL                // Filial Visao
            TRBCAB_N->ZCA_VALOR	:= QRYCAB_N->VALOR                  // Valor Filial
            TRBCAB_N->ZCA_VERSAO := _cVersao                        // Versão
            TRBCAB_N->ZCA_MESANO := _cMesAno                        // Mês/Ano Emis
            TRBCAB_N->ZCA_DTEMIS := Date()                          // Data Emissao
            TRBCAB_N->ZCA_HREMIS := Time()                          // Hora Emissao
            TRBCAB_N->ZCA_USUARI := __cUserId                       // Usuario Fech

            AAdd(_aItem1N, {"14", "Total–Superior ao 4o Mes", QRYCAB_N->FILIAL, QRYCAB_N->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_N->(DbSkip())      
        EndDo

        If Len(_aItem1N) > 0
            AAdd(_aCabec,{"14-Total Sup. 4º Mês Sint",_aCab1})
            AAdd(_aCabec,{"14-Total Sup. 4º Mês Anal",_aCab2})
            AAdd(_aItem,_aItem1N)
        Endif   

        Do While ! QRYDET_N->(Eof())
            IncProc("Lendo dados Analítico - 14-Totalizador–Superior ao 4o Mes")
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")                       //	Filial
            ZCB->ZCB_VISAO	 := "14"                                //	Item Visao
            ZCB->ZCB_FILVIS := "Total–Superior ao 4o Mes"           //	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao                             //	Versão
            ZCB->ZCB_MESANO := _cMesAno                             //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()                               //	Data Emissao
            ZCB->ZCB_HREMIS := Time()                               //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId                            //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_N->E1_NUM                     //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_N->E1_PREFIXO                 //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_N->E1_PARCELA                 //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_N->E1_TIPO                    //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_N->E1_CLIENTE                 //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_N->E1_LOJA                    //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_N->E1_NOMCLI                  //	Nome
            ZCB->ZCB_VALOR  := QRYDET_N->E1_SALDO                   //	Valor
            ZCB->ZCB_EMISSA := Stod(QRYDET_N->E1_EMISSAO)           //	Emissão
            ZCB->(MsUnLock())  

            TRBDET_N->(DbAppend())
            //TRBDET_N->ZCB_FILIAL := xFilial("ZCB")                //	Filial
            TRBDET_N->ZCB_VISAO	 := "14"                            //	Item Visao
            TRBDET_N->ZCB_FILVIS := "Total–Superior ao 4o Mes"      //	Filial Visao
            TRBDET_N->ZCB_VERSAO := _cVersao                        //	Versão
            TRBDET_N->ZCB_MESANO := _cMesAno                        //	Mês/Ano Emis
            TRBDET_N->ZCB_DTEMIS := Date()                          //	Data Emissao
            TRBDET_N->ZCB_HREMIS := Time()                          //	Hora Emissao
            TRBDET_N->ZCB_USUARI := __cUserId                       //	Usuario Fech
            TRBDET_N->ZCB_NUMTIT := QRYDET_N->E1_NUM                //	No. Titulo  
            TRBDET_N->ZCB_PREFIX := QRYDET_N->E1_PREFIXO            //	Prefixo     
            TRBDET_N->ZCB_PARCEL := QRYDET_N->E1_PARCELA            //	Parcerla
            TRBDET_N->ZCB_TIPO   := QRYDET_N->E1_TIPO               //	Tipo
            TRBDET_N->ZCB_CLIENT := QRYDET_N->E1_CLIENTE            //	Cliente 
            TRBDET_N->ZCB_LOJA   := QRYDET_N->E1_LOJA               //	Loja
            TRBDET_N->ZCB_NOMCLI := QRYDET_N->E1_NOMCLI             //	Nome
            TRBDET_N->ZCB_VALOR  := QRYDET_N->E1_SALDO              //	Valor
            TRBDET_N->ZCB_EMISSA := Stod(QRYDET_N->E1_EMISSAO)      //	Emissão

            AAdd(_aItem2N, {"14", "Total–Superior ao 4o Mes", _cVersao, _cMesAno, Date(), Time(), __cUserId, QRYDET_N->E1_NUM, QRYDET_N->E1_PREFIXO, QRYDET_N->E1_PARCELA, QRYDET_N->E1_TIPO, QRYDET_N->E1_CLIENTE, QRYDET_N->E1_LOJA, QRYDET_N->E1_NOMCLI, QRYDET_N->E1_SALDO, Stod(QRYDET_N->E1_EMISSAO)})
            QRYDET_N->(DbSkip())  
        EndDo

        If Len(_aItem2N) > 0
            AAdd(_aItem,_aItem2N)
        Endif 
    EndIf

    //===============================================
    // 15-Total–Emitidas e Vencidas no Mesmo Mes = O
    //===============================================
    If _cAbas == "00" .Or. _cAbas == "15"
        IncProc("Gerando dados: 15-Totalizador–Emitidas e Vencidas no Mesmo Mes")
        _cDataIni := "01/" + SubStr(MV_PAR01,1,2) + "/" + SubStr(MV_PAR01,3,4)
        _dDataIni := Ctod(_cDataIni)
        _cDataVen := Dtos(_dDataIni)
        _cAnoMesV := Substr(_cDataVen,1,6)
        _cDataEmi := Dtos(_dDataIni)
        _cAnoMesE := SubStr(_cDataEmi,1,6)
        //-------- Query Sintético
        _cQry := " SELECT FILIAL, SUM(VALOR) VALOR "
        _cQry += " FROM ( "
        _cQry += " SELECT E1_FILIAL FILIAL, SUM(E1_SALDO) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry += " AND E1_ORIGEM='MATA460' "  
        _cQry += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY E1_FILIAL "
        _cQry += " ) "
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (FILIAL) "
        _cQry += " ORDER BY FILIAL "  

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_SALDO,  E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry2 += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry2 += " AND E1_ORIGEM='MATA460' "  
        _cQry2 += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry2 += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL, E1_NUM "

        MPSysOpenQuery( _cQry , "QRYCAB_O")
        DBSelectArea("QRYCAB_O")
        
        Count To _nTotRCab
        QRYCAB_O->(DbGotop())
        
        MPSysOpenQuery( _cQry2 , "QRYDET_O")
        DBSelectArea("QRYDET_O")
        
        Count To _nTotRDet
        QRYDET_O->(DbGotop())

        Do While ! QRYCAB_O->(Eof())
            IncProc("Lendo dados Sintético - 15-Totalizador–Emitidas e Vencidas no Mesmo Mes")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                           // Filial
            ZCA->ZCA_VISAO	 := "15"                                    // Item Visao
            ZCA->ZCA_DESVIS := "Total–Emitidas e Vencidas no Mesmo Mes" // Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_O->FILIAL                         // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_O->VALOR                         // Valor Filial
            ZCA->ZCA_VERSAO := _cVersao                                 // Versão
            ZCA->ZCA_MESANO := _cMesAno                                 // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()                                   // Data Emissao
            ZCA->ZCA_HREMIS := Time()                                   // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId                                // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_O->(DbAppend())
            //TRBCAB_O->ZCA_FILIAL := xFilial("ZCA")                        // Filial
            TRBCAB_O->ZCA_VISAO	:= "15"                                     // Item Visao
            TRBCAB_O->ZCA_DESVIS := "Total–Emitidas e Vencidas no Mesmo Mes"// Descr.Visao
            TRBCAB_O->ZCA_FILVIS := QRYCAB_O->FILIAL                        // Filial Visao
            TRBCAB_O->ZCA_VALOR	:= QRYCAB_O->VALOR                          // Valor Filial
            TRBCAB_O->ZCA_VERSAO := _cVersao                                // Versão
            TRBCAB_O->ZCA_MESANO := _cMesAno                                // Mês/Ano Emis
            TRBCAB_O->ZCA_DTEMIS := Date()                                  // Data Emissao
            TRBCAB_O->ZCA_HREMIS := Time()                                  // Hora Emissao
            TRBCAB_O->ZCA_USUARI := __cUserId                               // Usuario Fech

            AAdd(_aItem1O, {"15", "Total–Emitidas e Vencidas no Mesmo Mes", QRYCAB_O->FILIAL, QRYCAB_O->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_O->(DbSkip())      
        EndDo

        If Len(_aItem1O) > 0
            AAdd(_aCabec,{"15-Emit./Venc. Mesmo Mês Sint",_aCab1})
            AAdd(_aCabec,{"15-Emit./Venc. Mesmo Mês Anal",_aCab2})
            AAdd(_aItem,_aItem1O)
        Endif

        Do While ! QRYDET_O->(Eof())
            IncProc("Lendo dados Analítico - 15-Totalizador–Emitidas e Vencidas no Mesmo Mes")
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")                           //	Filial
            ZCB->ZCB_VISAO	 := "15"                                    //	Item Visao
            ZCB->ZCB_FILVIS := "Total–Emitidas e Vencidas no Mesmo Mes" //	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao                                 //	Versão
            ZCB->ZCB_MESANO := _cMesAno                                 //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()                                   //	Data Emissao
            ZCB->ZCB_HREMIS := Time()                                   //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId                                //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_O->E1_NUM                         //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_O->E1_PREFIXO                     //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_O->E1_PARCELA                     //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_O->E1_TIPO                        //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_O->E1_CLIENTE                     //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_O->E1_LOJA                        //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_O->E1_NOMCLI                      //	Nome
            ZCB->ZCB_VALOR  := QRYDET_O->E1_SALDO                       //	Valor
            ZCB->ZCB_EMISSA := Stod(QRYDET_O->E1_EMISSAO)               //	Emissão
            ZCB->(MsUnLock())  

            TRBDET_O->(DbAppend())
            //TRBDET_O->ZCB_FILIAL := xFilial("ZCB")                        //	Filial
            TRBDET_O->ZCB_VISAO	 := "15"                                    //	Item Visao
            TRBDET_O->ZCB_FILVIS := "Total–Emitidas e Vencidas no Mesmo Mes"//	Filial Visao
            TRBDET_O->ZCB_VERSAO := _cVersao                                //	Versão
            TRBDET_O->ZCB_MESANO := _cMesAno                                //	Mês/Ano Emis
            TRBDET_O->ZCB_DTEMIS := Date()                                  //	Data Emissao
            TRBDET_O->ZCB_HREMIS := Time()                                  //	Hora Emissao
            TRBDET_O->ZCB_USUARI := __cUserId                               //	Usuario Fech
            TRBDET_O->ZCB_NUMTIT := QRYDET_O->E1_NUM                        //	No. Titulo  
            TRBDET_O->ZCB_PREFIX := QRYDET_O->E1_PREFIXO                    //	Prefixo     
            TRBDET_O->ZCB_PARCEL := QRYDET_O->E1_PARCELA                    //	Parcerla
            TRBDET_O->ZCB_TIPO   := QRYDET_O->E1_TIPO                       //	Tipo
            TRBDET_O->ZCB_CLIENT := QRYDET_O->E1_CLIENTE                    //	Cliente 
            TRBDET_O->ZCB_LOJA   := QRYDET_O->E1_LOJA                       //	Loja
            TRBDET_O->ZCB_NOMCLI := QRYDET_O->E1_NOMCLI                     //	Nome
            TRBDET_O->ZCB_VALOR  := QRYDET_O->E1_SALDO                      //	Valor
            TRBDET_O->ZCB_EMISSA := Stod(QRYDET_O->E1_EMISSAO)              //	Emissão

            AAdd(_aItem2O, {"15", "Total–Emitidas e Vencidas no Mesmo Mes", _cVersao, _cMesAno, Date(), Time(), __cUserId, QRYDET_O->E1_NUM, QRYDET_O->E1_PREFIXO, QRYDET_O->E1_PARCELA, QRYDET_O->E1_TIPO, QRYDET_O->E1_CLIENTE, QRYDET_O->E1_LOJA, QRYDET_O->E1_NOMCLI, QRYDET_O->E1_SALDO, Stod(QRYDET_O->E1_EMISSAO)})
            QRYDET_O->(DbSkip())  
        EndDo

        If Len(_aItem2O) > 0
            AAdd(_aItem,_aItem2O)
        Endif 
    EndIf

    //================================================================================
    // 16-Totalizador–Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes  = P
    //================================================================================
    If _cAbas == "00" .Or. _cAbas == "16"
        IncProc("Gerando dados: 16-Totalizador–Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes")
        _cDataIni := "01/" + SubStr(MV_PAR01,1,2) + "/" + SubStr(MV_PAR01,3,4)
        _dDataIni := Ctod(_cDataIni)
        _cDataVen := Dtos(_dDataIni)
        _cAnoMesV := Substr(_cDataVen,1,6)
        _cDataEmi := Dtos(_dDataIni)
        _cAnoMesE := SubStr(_cDataEmi,1,6)
        //-------- Query Sintético
        _cQry := " SELECT FILIAL, SUM(VALOR) VALOR "
        _cQry += " FROM ( "
        _cQry += " SELECT E1_FILIAL FILIAL, SUM(E1_SALDO) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry += " AND E1_ORIGEM='MATA460' "  
        _cQry += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY E1_FILIAL "
        _cQry += " ) "
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (FILIAL) "
        _cQry += " ORDER BY FILIAL "  

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E1_SALDO,  E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "      
        _cQry2 += " WHERE SUBSTR(E1_EMISSAO,1,6) = '" + _cAnoMesE + "' "  
        _cQry2 += " AND E1_ORIGEM='MATA460' "  
        _cQry2 += " AND SUBSTR(E1_VENCREA,1,6) = '" + _cAnoMesV + "' "  
        _cQry2 += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL, E1_NUM "

       MPSysOpenQuery( _cQry , "QRYCAB_P")
        DBSelectArea("QRYCAB_P")
        
        Count To _nTotRCab
        QRYCAB_P->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_P")
        DBSelectArea("QRYDET_P")
        
        Count To _nTotRDet
        QRYDET_P->(DbGotop())

        Do While ! QRYCAB_P->(Eof())
            IncProc("Lendo dados Sintético - 16-Totalizador–Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes ")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                                                   // Filial
            ZCA->ZCA_VISAO	 := "16"                                                            // Item Visao
            ZCA->ZCA_DESVIS := "Total–Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes" // Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_P->FILIAL                                                 // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_P->VALOR                                                 // Valor Filial
            ZCA->ZCA_VERSAO := _cVersao                                                         // Versão
            ZCA->ZCA_MESANO := _cMesAno                                                         // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()                                                           // Data Emissao
            ZCA->ZCA_HREMIS := Time()                                                           // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId                                                        // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_P->(DbAppend())
            //TRBCAB_P->ZCA_FILIAL := xFilial("ZCA")                                                // Filial
            TRBCAB_P->ZCA_VISAO	:= "16"                                                             // Item Visao
            TRBCAB_P->ZCA_DESVIS := "Total–Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes"// Descr.Visao
            TRBCAB_P->ZCA_FILVIS := QRYCAB_P->FILIAL                                                // Filial Visao
            TRBCAB_P->ZCA_VALOR	:= QRYCAB_P->VALOR                                                  // Valor Filial
            TRBCAB_P->ZCA_VERSAO := _cVersao                                                        // Versão
            TRBCAB_P->ZCA_MESANO := _cMesAno                                                        // Mês/Ano Emis
            TRBCAB_P->ZCA_DTEMIS := Date()                                                          // Data Emissao
            TRBCAB_P->ZCA_HREMIS := Time()                                                          // Hora Emissao
            TRBCAB_P->ZCA_USUARI := __cUserId                                                       // Usuario Fech

            AAdd(_aItem1P, {"16", "Total–Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes", QRYCAB_P->FILIAL, QRYCAB_P->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_P->(DbSkip())      
        EndDo

        If Len(_aItem1P) > 0
            AAdd(_aCabec,{"16-Venc Mês/Emis. Anter Sint",_aCab1})
            AAdd(_aCabec,{"16-Venc Mês/Emis. Anter Anal",_aCab2})
            AAdd(_aItem,_aItem1P)
        Endif

        Do While ! QRYDET_P->(Eof())
            IncProc("Lendo dados Analítico - 16-Totalizador–Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes ")
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")                                                   //	Filial
            ZCB->ZCB_VISAO	 := "16"                                                            //	Item Visao
            ZCB->ZCB_FILVIS := "Total–Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes" //	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao                                                         //	Versão
            ZCB->ZCB_MESANO := _cMesAno                                                         //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()                                                           //	Data Emissao
            ZCB->ZCB_HREMIS := Time()                                                           //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId                                                        //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_P->E1_NUM                                                 //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_P->E1_PREFIXO                                             //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_P->E1_PARCELA                                             //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_P->E1_TIPO                                                //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_P->E1_CLIENTE                                             //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_P->E1_LOJA                                                //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_P->E1_NOMCLI                                              //	Nome
            ZCB->ZCB_VALOR  := QRYDET_P->E1_SALDO                                               //	Valor
            ZCB->ZCB_EMISSA := Stod(QRYDET_P->E1_EMISSAO)                                       //	Emissão
            ZCB->(MsUnLock())  

            TRBDET_P->(DbAppend())
            //TRBDET_P->ZCB_FILIAL := xFilial("ZCB")                                                    //	Filial
            TRBDET_P->ZCB_VISAO	 := "16"                                                                //	Item Visao
            TRBDET_P->ZCB_FILVIS := "Total–Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes"    //	Filial Visao
            TRBDET_P->ZCB_VERSAO := _cVersao                                                            //	Versão
            TRBDET_P->ZCB_MESANO := _cMesAno                                                            //	Mês/Ano Emis
            TRBDET_P->ZCB_DTEMIS := Date()                                                              //	Data Emissao
            TRBDET_P->ZCB_HREMIS := Time()                                                              //	Hora Emissao
            TRBDET_P->ZCB_USUARI := __cUserId                                                           //	Usuario Fech
            TRBDET_P->ZCB_NUMTIT := QRYDET_P->E1_NUM                                                    //	No. Titulo  
            TRBDET_P->ZCB_PREFIX := QRYDET_P->E1_PREFIXO                                                //	Prefixo     
            TRBDET_P->ZCB_PARCEL := QRYDET_P->E1_PARCELA                                                //	Parcerla
            TRBDET_P->ZCB_TIPO   := QRYDET_P->E1_TIPO                                                   //	Tipo
            TRBDET_P->ZCB_CLIENT := QRYDET_P->E1_CLIENTE                                                //	Cliente 
            TRBDET_P->ZCB_LOJA   := QRYDET_P->E1_LOJA                                                   //	Loja
            TRBDET_P->ZCB_NOMCLI := QRYDET_P->E1_NOMCLI                                                 //	Nome
            TRBDET_P->ZCB_VALOR  := QRYDET_P->E1_SALDO                                                  //	Valor
            TRBDET_P->ZCB_EMISSA := Stod(QRYDET_P->E1_EMISSAO)                                          //	Emissão

            AAdd(_aItem2P, {"16", "Total–Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes", _cVersao, _cMesAno, Date(), Time(), __cUserId, QRYDET_P->E1_NUM, QRYDET_P->E1_PREFIXO, QRYDET_P->E1_PARCELA, QRYDET_P->E1_TIPO, QRYDET_P->E1_CLIENTE, QRYDET_P->E1_LOJA, QRYDET_P->E1_NOMCLI, QRYDET_P->E1_SALDO, Stod(QRYDET_P->E1_EMISSAO)})
            QRYDET_P->(DbSkip())  
        EndDo

        If Len(_aItem2P) > 0
            AAdd(_aItem,_aItem2P)
        Endif
    EndIf

    //=========================================
    // 17–Vendas do Mes Recebidas no Mes = Q
    //=========================================
    If _cAbas == "00" .Or. _cAbas == "17"
        IncProc("Gerando dados: 17–Vendas do Mes Recebidas no Mes")
        //-------- Query Sintético
        _cQry := " SELECT E5_FILIAL FILIAL, SUM(E5_VALOR) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "  
        _cQry += " INNER JOIN  " + RetSqlName("SE5") + " SE5 ON E5_FILIAL = E1_FILIAL AND E5_NUMERO = E1_NUM AND E5_PREFIXO = E1_PREFIXO AND E5_CLIFOR = E1_CLIENTE "
        _cQry += " AND E5_LOJA = E1_LOJA "
        _cQry += " AND SE5.D_E_L_E_T_ =' ' AND E5_MOTBX='NOR' "
        _cQry += " AND Substr(E5_DATA,1,6) = '" +  _cAnoMes  +"' "
        _cQry += " AND E1_PARCELA = E5_PARCELA "
        _cQry += " WHERE SubStr(E1_EMISSAO,1,6) = '" +  _cAnoMes + "' AND SE1.D_E_L_E_T_ =' ' AND E5_TIPODOC='VL' "
        _cQry += " AND ( (E1_TIPO='NF' AND E1_ORIGEM='MATA460') OR ( E1_TIPO='NF' AND E1_PREFIXO='R') OR (E1_TIPO='ICM' ) OR (E1_TIPO='NDC') OR (E1_TIPO='RC') ) "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (E5_FILIAL) "
        _cQry += " ORDER BY E5_FILIAL "

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E5_VALOR,  E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "  
        _cQry2 += " INNER JOIN  " + RetSqlName("SE5") + " SE5 ON E5_FILIAL = E1_FILIAL AND E5_NUMERO = E1_NUM AND E5_PREFIXO = E1_PREFIXO AND E5_CLIFOR = E1_CLIENTE "
        _cQry2 += " AND E5_LOJA = E1_LOJA "
        _cQry2 += " AND SE5.D_E_L_E_T_ =' ' AND E5_MOTBX='NOR' "
        _cQry2 += " AND Substr(E5_DATA,1,6) = '" +  _cAnoMes +"' "
        _cQry2 += " AND E1_PARCELA = E5_PARCELA "
        _cQry2 += " WHERE SubStr(E1_EMISSAO,1,6) = '" +  _cAnoMes + "' AND SE1.D_E_L_E_T_ =' ' AND E5_TIPODOC='VL' "
        _cQry2 += " AND ( (E1_TIPO='NF' AND E1_ORIGEM='MATA460') OR ( E1_TIPO='NF' AND E1_PREFIXO='R') OR (E1_TIPO='ICM' ) OR (E1_TIPO='NDC') OR (E1_TIPO='RC') ) "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL, E1_NUM "

        MPSysOpenQuery( _cQry , "QRYCAB_Q")
        DBSelectArea("QRYCAB_Q")
        
        Count To _nTotRCab
        QRYCAB_Q->(DbGotop())
        
        MPSysOpenQuery( _cQry2 , "QRYDET_Q")
        DBSelectArea("QRYDET_Q")
        
        Count To _nTotRDet
        QRYDET_Q->(DbGotop())

        Do While ! QRYCAB_Q->(Eof())
            IncProc("Lendo dados Sintético - 17–Vendas do Mes Recebidas no Mes")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                       // Filial
            ZCA->ZCA_VISAO	 := "17"                                // Item Visao
            ZCA->ZCA_DESVIS := "Vendas do Mes Recebidas no Mes"	    // Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_Q->FILIAL	                    // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_Q->VALOR                     // Valor Filial
            ZCA->ZCA_VERSAO := _cVersao	                            // Versão
            ZCA->ZCA_MESANO := MV_PAR01	                            // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()	                            // Data Emissao
            ZCA->ZCA_HREMIS := Time()	                            // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId 	                        // Usuario Fech
		    ZCA->(MsUnLock())		

            TRBCAB_Q->(DbAppend())
            //TRBCAB_Q->ZCA_FILIAL := xFilial("ZCA")                    // Filial
            TRBCAB_Q->ZCA_VISAO	:= "17"                                 // Item Visao
            TRBCAB_Q->ZCA_DESVIS := "Vendas do Mes Recebidas no Mes"	// Descr.Visao
            TRBCAB_Q->ZCA_FILVIS := QRYCAB_Q->FILIAL	                // Filial Visao
            TRBCAB_Q->ZCA_VALOR	:= QRYCAB_Q->VALOR                      // Valor Filial
            TRBCAB_Q->ZCA_VERSAO := _cVersao	                        // Versão
            TRBCAB_Q->ZCA_MESANO := MV_PAR01	                        // Mês/Ano Emis
            TRBCAB_Q->ZCA_DTEMIS := Date()	                            // Data Emissao
            TRBCAB_Q->ZCA_HREMIS := Time()	                            // Hora Emissao
            TRBCAB_Q->ZCA_USUARI := __cUserId 	                        // Usuario Fech

            AAdd(_aItem1Q, {"17", "Vendas do Mes Recebidas no Mes", QRYCAB_Q->FILIAL, QRYCAB_Q->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_Q->(DbSkip())      
        EndDo

        If Len(_aItem1Q) > 0
            AAdd(_aCabec,{"17-Vendas/Recbto no Mês Sint",_aCab1})
            AAdd(_aCabec,{"17-Vendas/Recbto no Mês Anal",_aCab2})
            AAdd(_aItem,_aItem1Q)
        Endif   

        Do While ! QRYDET_Q->(Eof())
            IncProc("Lendo dados Analítico - 17–Vendas do Mes Recebidas no Mes")
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")	                    //	Filial
            ZCB->ZCB_VISAO	 := "17"                                //	Item Visao
            ZCB->ZCB_FILVIS := "Vendas do Mes Recebidas no Mes" 	//	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao	                            //	Versão
            ZCB->ZCB_MESANO := MV_PAR01	                            //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()	                            //	Data Emissao
            ZCB->ZCB_HREMIS := Time()	                            //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId	                        //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_Q->E1_NUM                     //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_Q->E1_PREFIXO                 //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_Q->E1_PARCELA	                //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_Q->E1_TIPO   	                //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_Q->E1_CLIENTE	                //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_Q->E1_LOJA	                //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_Q->E1_NOMCLI	                //	Nome
            ZCB->ZCB_VALOR  := QRYDET_Q->E5_VALOR	                //	Valor
            ZCB->ZCB_EMISSA := Stod(QRYDET_Q->E1_EMISSAO)           //	Emissão
            ZCB->(MsUnLock()) 

            TRBDET_Q->(DbAppend())
            //TRBDET_Q->ZCB_FILIAL := xFilial("ZCB")	                //	Filial
            TRBDET_Q->ZCB_VISAO  := "17"                                //	Item Visao
            TRBDET_Q->ZCB_FILVIS := "Vendas do Mes Recebidas no Mes"	//	Filial Visao
            TRBDET_Q->ZCB_VERSAO := _cVersao	                        //	Versão
            TRBDET_Q->ZCB_MESANO := MV_PAR01	                        //	Mês/Ano Emis
            TRBDET_Q->ZCB_DTEMIS := Date()	                            //	Data Emissao
            TRBDET_Q->ZCB_HREMIS := Time()	                            //	Hora Emissao
            TRBDET_Q->ZCB_USUARI := __cUserId	                        //	Usuario Fech
            TRBDET_Q->ZCB_NUMTIT := QRYDET_Q->E1_NUM                    //	No. Titulo  
            TRBDET_Q->ZCB_PREFIX := QRYDET_Q->E1_PREFIXO                //	Prefixo     
            TRBDET_Q->ZCB_PARCEL := QRYDET_Q->E1_PARCELA	            //	Parcerla
            TRBDET_Q->ZCB_TIPO   := QRYDET_Q->E1_TIPO   	            //	Tipo
            TRBDET_Q->ZCB_CLIENT := QRYDET_Q->E1_CLIENTE	            //	Cliente 
            TRBDET_Q->ZCB_LOJA   := QRYDET_Q->E1_LOJA	                //	Loja
            TRBDET_Q->ZCB_NOMCLI := QRYDET_Q->E1_NOMCLI	                //	Nome
            TRBDET_Q->ZCB_VALOR  := QRYDET_Q->E5_VALOR	                //	Valor
            TRBDET_Q->ZCB_EMISSA := Stod(QRYDET_Q->E1_EMISSAO)          //	Emissão

            AAdd(_aItem2Q, {"17", "Vendas Recebidas no Mes", _cVersao, MV_PAR01, Date(), Time(), __cUserId, QRYDET_Q->E1_NUM, QRYDET_Q->E1_PREFIXO, QRYDET_Q->E1_PARCELA, QRYDET_Q->E1_TIPO, QRYDET_Q->E1_CLIENTE, QRYDET_Q->E1_LOJA, QRYDET_Q->E1_NOMCLI, QRYDET_Q->E5_VALOR, Stod(QRYDET_Q->E1_EMISSAO)})
            QRYDET_Q->(DbSkip())  
        EndDo

        If Len(_aItem2Q) > 0
            AAdd(_aItem,_aItem2Q)
        Endif 
    EndIf

    //=========================================
   // 18-Devolvidas-RA Compensadas = R
   //=========================================
    If _cAbas == "00" .Or. _cAbas == "18"
        IncProc("Gerando dados: 18-Devolvidas-RA Compensadas")
        //-------- Query Sintético
        _cQry := " SELECT E5_FILIAL FILIAL, SUM(E5_VALOR) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "  
        _cQry += " INNER JOIN  " + RetSqlName("SE5") + " SE5 ON  E5_FILIAL = E1_FILIAL AND E5_NUMERO = E1_NUM AND E5_PREFIXO = E1_PREFIXO AND E5_CLIFOR = E1_CLIENTE " 
        _cQry += " AND E5_LOJA = E1_LOJA "
        _cQry += " AND SE5.D_E_L_E_T_ =' ' AND E5_MOTBX='CMP' "
        _cQry += " AND Substr(E5_DATA,1,6) = '" +  _cAnoMes  +"' "
        _cQry += " AND E5_PARCELA = E1_PARCELA AND SUBSTR(E5_DOCUMEN,15,2) ='RA' "
        _cQry += " WHERE SubStr(E1_EMISSAO,1,6) = '" +  _cAnoMes + "' 
        _cQry += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (E5_FILIAL) "
        _cQry += " ORDER BY E5_FILIAL "

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E5_VALOR,  E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "  
        _cQry2 += " INNER JOIN  " + RetSqlName("SE5") + " SE5 ON  E5_FILIAL = E1_FILIAL AND E5_NUMERO = E1_NUM AND E5_PREFIXO = E1_PREFIXO AND E5_CLIFOR = E1_CLIENTE " 
        _cQry2 += " AND E5_LOJA = E1_LOJA "
        _cQry2 += " AND SE5.D_E_L_E_T_ =' ' AND E5_MOTBX='CMP' "
        _cQry2 += " AND Substr(E5_DATA,1,6) = '" +  _cAnoMes  +"' "
        _cQry2 += " AND E5_PARCELA = E1_PARCELA AND SUBSTR(E5_DOCUMEN,15,2) ='RA' "
        _cQry2 += " WHERE SubStr(E1_EMISSAO,1,6) = '" +  _cAnoMes + "' 
        _cQry2 += " AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO = 'NF' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
       _cQry2 += " ORDER BY E5_FILIAL,E1_NUM "

        MPSysOpenQuery( _cQry , "QRYCAB_R")
        DBSelectArea("QRYCAB_R")
        
        Count To _nTotRCab
        QRYCAB_R->(DbGotop())
        
        MPSysOpenQuery( _cQry2 , "QRYDET_R")
        DBSelectArea("QRYDET_R")
        
        Count To _nTotRDet
        QRYDET_R->(DbGotop())

        Do While ! QRYCAB_R->(Eof())
            IncProc("Lendo dados Sintético - 18-Devolvidas-RA Compensadas")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                       // Filial
            ZCA->ZCA_VISAO	 := "18"                                // Item Visao
            ZCA->ZCA_DESVIS := "18-Devolvidas-RA Compensadas"	    // Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_R->FILIAL	                    // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_R->VALOR                     // Valor Filial
            ZCA->ZCA_VERSAO := _cVersao	                            // Versão
            ZCA->ZCA_MESANO := MV_PAR01	                            // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()	                            // Data Emissao
            ZCA->ZCA_HREMIS := Time()	                            // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId 	                        // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_R->(DbAppend())
            //TRBCAB_R->ZCA_FILIAL := xFilial("ZCA")                // Filial
            TRBCAB_R->ZCA_VISAO	:= "18"                             // Item Visao
            TRBCAB_R->ZCA_DESVIS := "Devolvidas-RA Compensadas"	    // Descr.Visao
            TRBCAB_R->ZCA_FILVIS := QRYCAB_R->FILIAL	            // Filial Visao
            TRBCAB_R->ZCA_VALOR	:= QRYCAB_R->VALOR                  // Valor Filial
            TRBCAB_R->ZCA_VERSAO := _cVersao	                    // Versão
            TRBCAB_R->ZCA_MESANO := MV_PAR01	                    // Mês/Ano Emis
            TRBCAB_R->ZCA_DTEMIS := Date()	                        // Data Emissao
            TRBCAB_R->ZCA_HREMIS := Time()	                        // Hora Emissao
            TRBCAB_R->ZCA_USUARI := __cUserId 	                    // Usuario Fech

            AAdd(_aItem1R, {"18", "Total–9o Mes Seguinte", QRYCAB_R->FILIAL, QRYCAB_R->VALOR, _cVersao, _cMesAno, Date(), Time(), __cUserId})
            QRYCAB_R->(DbSkip())      
        EndDo

        If Len(_aItem1R) > 0
            AAdd(_aCabec,{"18-Dev. RA Compensadas Sint",_aCab1})
            AAdd(_aCabec,{"18-Dev. RA Compensadas Anal",_aCab2})
            AAdd(_aItem,_aItem1R)
        Endif

        Do While ! QRYDET_R->(Eof())
            IncProc("Lendo dados Analítico - 18-Devolvidas-RA Compensadas")
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")	                //	Filial
            ZCB->ZCB_VISAO	 := "18"                            //	Item Visao
            ZCB->ZCB_FILVIS := "Devolvidas-RA Compensadas" 	    //	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao	                        //	Versão
            ZCB->ZCB_MESANO := MV_PAR01	                        //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()	                        //	Data Emissao
            ZCB->ZCB_HREMIS := Time()	                        //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId	                    //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_R->E1_NUM                 //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_R->E1_PREFIXO             //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_R->E1_PARCELA	            //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_R->E1_TIPO   	            //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_R->E1_CLIENTE	            //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_R->E1_LOJA	            //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_R->E1_NOMCLI	            //	Nome
            ZCB->ZCB_VALOR  := QRYDET_R->E5_VALOR	            //	Valor
            ZCB->ZCB_EMISSA := Stod(QRYDET_R->E1_EMISSAO)       //	Emissão
            ZCB->(MsUnLock()) 

            TRBDET_R->(DbAppend())
            //TRBDET_R->ZCB_FILIAL := xFilial("ZCB")	         //	Filial
            TRBDET_R->ZCB_VISAO  := "18"                         //	Item Visao
            TRBDET_R->ZCB_FILVIS := "Devolvidas-RA Compensadas"	 //	Filial Visao
            TRBDET_R->ZCB_VERSAO := _cVersao	                 //	Versão
            TRBDET_R->ZCB_MESANO := MV_PAR01	                 //	Mês/Ano Emis
            TRBDET_R->ZCB_DTEMIS := Date()	                     //	Data Emissao
            TRBDET_R->ZCB_HREMIS := Time()	                     //	Hora Emissao
            TRBDET_R->ZCB_USUARI := __cUserId	                 //	Usuario Fech
            TRBDET_R->ZCB_NUMTIT := QRYDET_R->E1_NUM             //	No. Titulo  
            TRBDET_R->ZCB_PREFIX := QRYDET_R->E1_PREFIXO         //	Prefixo     
            TRBDET_R->ZCB_PARCEL := QRYDET_R->E1_PARCELA	     //	Parcerla
            TRBDET_R->ZCB_TIPO   := QRYDET_R->E1_TIPO   	     //	Tipo
            TRBDET_R->ZCB_CLIENT := QRYDET_R->E1_CLIENTE	     //	Cliente 
            TRBDET_R->ZCB_LOJA   := QRYDET_R->E1_LOJA	         //	Loja
            TRBDET_R->ZCB_NOMCLI := QRYDET_R->E1_NOMCLI	         //	Nome
            TRBDET_R->ZCB_VALOR  := QRYDET_R->E5_VALOR	         //	Valor
            TRBDET_R->ZCB_EMISSA := Stod(QRYDET_R->E1_EMISSAO)   //	Emissão

            AAdd(_aItem2R, {"18", "Devolvidas-RA Compensadas", _cVersao, MV_PAR01, Date(), Time(), __cUserId, QRYDET_R->E1_NUM, QRYDET_R->E1_PREFIXO, QRYDET_R->E1_PARCELA, QRYDET_R->E1_TIPO, QRYDET_R->E1_CLIENTE, QRYDET_R->E1_LOJA, QRYDET_R->E1_NOMCLI, QRYDET_R->E5_VALOR, Stod(QRYDET_R->E1_EMISSAO)})
            QRYDET_R->(DbSkip())  
        EndDo

        If Len(_aItem2R) > 0
            AAdd(_aItem,_aItem2R)
        Endif
    EndIf

    //=============================================================
   // 19-Devolvidas-NCC Compensadas no Mês(Tipos NF com NCC) = S
   //=============================================================
    If _cAbas == "00" .Or. _cAbas == "19"
        IncProc("Gerando dados: 19-Devolvidas-NCC Compensadas no Mês(Tipos NF com NCC)")
       
       //-------- Query Sintético
        _cQry := " SELECT E5_FILIAL FILIAL, SUM(E5_VALOR) VALOR "
        _cQry += " FROM " + RetSqlName("SE1") + " SE1 "  
        _cQry += " INNER JOIN  " + RetSqlName("SE5") + " SE5 ON E5_FILIAL = E1_FILIAL AND E5_NUMERO = E1_NUM AND E5_PREFIXO = E1_PREFIXO AND E5_CLIFOR = E1_CLIENTE "
        _cQry += " AND E5_LOJA = E1_LOJA "
        _cQry += " AND SE5.D_E_L_E_T_ =' ' AND E5_MOTBX='CMP' "
        _cQry += " AND Substr(E5_DATA,1,6) = '" +  _cAnoMes  +"' "
        _cQry += " AND E5_PARCELA = E1_PARCELA AND SUBSTR(E5_DOCUMEN,15,3) ='NCC' "
        _cQry += " WHERE SubStr(E1_EMISSAO,1,6) = '" +  _cAnoMes + "'  AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        _cQry += " GROUP BY "
        _cQry += " ROLLUP (E5_FILIAL) "
        _cQry += " ORDER BY E5_FILIAL "

        //-------- Query Analítico
        _cQry2 := " SELECT E1_FILIAL, E1_NUM, E1_PREFIXO, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA, E1_NOMCLI, E5_VALOR,  E1_EMISSAO "
        _cQry2 += " FROM " + RetSqlName("SE1") + " SE1 "  
        _cQry2 += " INNER JOIN  " + RetSqlName("SE5") + " SE5 ON E5_FILIAL = E1_FILIAL AND E5_NUMERO = E1_NUM AND E5_PREFIXO = E1_PREFIXO AND E5_CLIFOR = E1_CLIENTE 
        _cQry2 += " AND E5_LOJA = E1_LOJA "
        _cQry2 += " AND SE5.D_E_L_E_T_ =' ' AND E5_MOTBX='CMP' "
        _cQry2 += " AND Substr(E5_DATA,1,6) = '" +  _cAnoMes  +"' "
        _cQry2 += " AND E5_PARCELA = E1_PARCELA AND SUBSTR(E5_DOCUMEN,15,3) ='NCC' "
        _cQry2 += " WHERE SubStr(E1_EMISSAO,1,6) = '" +  _cAnoMes + "'  AND SE1.D_E_L_E_T_ =' ' AND E1_TIPO='NF' "
        If !Empty(_cFilTit)
            _cQry2 += " AND E1_FILIAL IN" + _cFilTit
        EndIf
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"E1")
        EndIf
        _cQry2 += " ORDER BY E1_FILIAL, E1_NUM "

        MPSysOpenQuery( _cQry , "QRYCAB_S")
        DBSelectArea("QRYCAB_S")
        
        Count To _nTotRCab
        QRYCAB_S->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_S")
        DBSelectArea("QRYDET_S")

        Do While ! QRYCAB_S->(Eof())
            IncProc("Lendo dados Sintético - 19-Devolvidas-NCC Compensadas no Mês(Tipos NF com NCC)")
            ZCA->(RecLock("ZCA", .T.))
            ZCA->ZCA_FILIAL := xFilial("ZCA")                                           // Filial
            ZCA->ZCA_VISAO	 := "19"                                                    // Item Visao
            ZCA->ZCA_DESVIS := "Devolvidas-NCC Compensadas no Mês(Tipos NF com NCC)"	// Descr.Visao
            ZCA->ZCA_FILVIS := QRYCAB_S->FILIAL  	                                    // Filial Visao
            ZCA->ZCA_VALOR	 := QRYCAB_S->VALOR                                         // Valor Filial
            ZCA->ZCA_VERSAO := _cVersao	                                                // Versão
            ZCA->ZCA_MESANO := MV_PAR01	                                                // Mês/Ano Emis
            ZCA->ZCA_DTEMIS := Date()	                                                // Data Emissao
            ZCA->ZCA_HREMIS := Time()	                                                // Hora Emissao
            ZCA->ZCA_USUARI := __cUserId 	                                            // Usuario Fech
            ZCA->(MsUnLock())		

            TRBCAB_S->(DbAppend())
            //TRBCAB_S->ZCA_FILIAL := xFilial("ZCA")                                        // Filial
            TRBCAB_S->ZCA_VISAO	:= "19"                                                     // Item Visao
            TRBCAB_S->ZCA_DESVIS := "Devolvidas-NCC Compensadas no Mês(Tipos NF com NCC)"   // Descr.Visao
            TRBCAB_S->ZCA_FILVIS := QRYCAB_S->FILIAL	                                    // Filial Visao
            TRBCAB_S->ZCA_VALOR	:= QRYCAB_S->VALOR                                          // Valor Filial
            TRBCAB_S->ZCA_VERSAO := _cVersao	                                            // Versão
            TRBCAB_S->ZCA_MESANO := MV_PAR01	                                            // Mês/Ano Emis
            TRBCAB_S->ZCA_DTEMIS := Date()	                                                // Data Emissao
            TRBCAB_S->ZCA_HREMIS := Time()	                                                // Hora Emissao
            TRBCAB_S->ZCA_USUARI := __cUserId 	                                            // Usuario Fech

            AAdd(_aItem1S, {"19", "Devolvidas-NCC Compensadas no Mês(Tipos NF com NCC)", QRYCAB_S->FILIAL, QRYCAB_S->VALOR, _cVersao, MV_PAR01, Date(), Time(), __cUserId})
            QRYCAB_S->(DbSkip())      
        EndDo

        If Len(_aItem1S) > 0
            AAdd(_aCabec,{"19-Dev NCC Compens Mês Sint",_aCab1})
            AAdd(_aCabec,{"19-Dev NCC Compens Mês Anal",_aCab2})
            AAdd(_aItem,_aItem1S)
        Endif 

        Do While ! QRYDET_S->(Eof())
            IncProc("Lendo dados Analítico - 19-Devolvidas-NCC Compensadas no Mês(Tipos NF com NCC)")      
            ZCB->(RecLock("ZCB", .T.))
            ZCB->ZCB_FILIAL := xFilial("ZCB")	                                        //	Filial
            ZCB->ZCB_VISAO	 := "19"                                                    //	Item Visao
            ZCB->ZCB_FILVIS := "Devolvidas-NCC Compensadas no Mês(Tipos NF com NCC)" 	//	Filial Visao
            ZCB->ZCB_VERSAO := _cVersao	                                                //	Versão
            ZCB->ZCB_MESANO := MV_PAR01	                                                //	Mês/Ano Emis
            ZCB->ZCB_DTEMIS := Date()	                                                //	Data Emissao
            ZCB->ZCB_HREMIS := Time()	                                                //	Hora Emissao
            ZCB->ZCB_USUARI := __cUserId	                                            //	Usuario Fech
            ZCB->ZCB_NUMTIT := QRYDET_S->E1_NUM                                         //	No. Titulo  
            ZCB->ZCB_PREFIX := QRYDET_S->E1_PREFIXO                                     //	Prefixo     
            ZCB->ZCB_PARCEL := QRYDET_S->E1_PARCELA	                                    //	Parcerla
            ZCB->ZCB_TIPO   := QRYDET_S->E1_TIPO   	                                    //	Tipo
            ZCB->ZCB_CLIENT := QRYDET_S->E1_CLIENTE	                                    //	Cliente 
            ZCB->ZCB_LOJA   := QRYDET_S->E1_LOJA	                                    //	Loja
            ZCB->ZCB_NOMCLI := QRYDET_S->E1_NOMCLI	                                    //	Nome
            ZCB->ZCB_VALOR  := QRYDET_S->E5_VALOR	                                    //	Valor
            ZCB->ZCB_EMISSA := Stod(QRYDET_S->E1_EMISSAO)	                            //	Emissão
            ZCB->(MsUnLock()) 

            TRBDET_S->(DbAppend())
            //TRBDET_S->ZCB_FILIAL := xFilial("ZCB")	                                    //	Filial
            TRBDET_S->ZCB_VISAO  := "19"                                                    //	Item Visao
            TRBDET_S->ZCB_FILVIS := "Devolvidas-NCC Compensadas no Mês(Tipos NF com NCC)"	//	Filial Visao
            TRBDET_S->ZCB_VERSAO := _cVersao	                                            //	Versão
            TRBDET_S->ZCB_MESANO := MV_PAR01	                                            //	Mês/Ano Emis
            TRBDET_S->ZCB_DTEMIS := Date()	                                                //	Data Emissao
            TRBDET_S->ZCB_HREMIS := Time()	                                                //	Hora Emissao
            TRBDET_S->ZCB_USUARI := __cUserId	                                            //	Usuario Fech
            TRBDET_S->ZCB_NUMTIT := QRYDET_S->E1_NUM                                        //	No. Titulo  
            TRBDET_S->ZCB_PREFIX := QRYDET_S->E1_PREFIXO                                    //	Prefixo     
            TRBDET_S->ZCB_PARCEL := QRYDET_S->E1_PARCELA	                                //	Parcerla
            TRBDET_S->ZCB_TIPO   := QRYDET_S->E1_TIPO   	                                //	Tipo
            TRBDET_S->ZCB_CLIENT := QRYDET_S->E1_CLIENTE	                                //	Cliente 
            TRBDET_S->ZCB_LOJA   := QRYDET_S->E1_LOJA	                                    //	Loja
            TRBDET_S->ZCB_NOMCLI := QRYDET_S->E1_NOMCLI	                                    //	Nome
            TRBDET_S->ZCB_VALOR  := QRYDET_S->E5_VALOR	                                    //	Valor
            TRBDET_S->ZCB_EMISSA := StoD(QRYDET_S->E1_EMISSAO)                              //	Emissão

            AAdd(_aItem2S, {"19", "Devolvidas-NCC Compensadas no Mês(Tipos NF com NCC)", _cVersao, MV_PAR01, Date(), Time(), __cUserId, QRYDET_S->E1_NUM, QRYDET_S->E1_PREFIXO, QRYDET_S->E1_PARCELA, QRYDET_S->E1_TIPO, QRYDET_S->E1_CLIENTE, QRYDET_S->E1_LOJA, QRYDET_S->E1_NOMCLI, QRYDET_S->E5_VALOR, StoD(QRYDET_S->E1_EMISSAO)})
            QRYDET_S->(DbSkip())  
        EndDo

        If Len(_aItem2S) > 0
            AAdd(_aItem,_aItem2S)
        Endif
    EndIf

    If _lTdAbas
        _cAbas := "00"
    EndIf

    End Sequence

Return Nil 

/*
===============================================================================================================================
Função-------------: AFIN040C
Autor--------------: Julio de Paula Paz
Data da Criacao----: 11/09/2025
Descrição----------: Retorna a ultima versão para o mês/ano i_nFormado.
Parametros---------: Nenhum
Retorno------------: _cRet = Ultima versão para o Mês/ano i_nFormado.
===============================================================================================================================
*/
Static Function AFIN040C()

    Local _cRet := "" As Character
    Local _cQry := "" As Character

    Begin Sequence 

    _cQry := " SELECT MAX(ZCA_VERSAO) VERSAO"
    _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
    _cQry += " WHERE ZCA.D_E_L_E_T_ = ' ' AND ZCA_MESANO = '" + MV_PAR01 + "' "

    MPSysOpenQuery( _cQry , "QRYVERSA")
    DBSelectArea("QRYVERSA")

    If ! QRYVERSA->(Eof()) .And. ! QRYVERSA->(Bof())
        _cRet := QRYVERSA->VERSAO
    EndIf 

    End Sequence 

Return _cRet 

/*
===============================================================================================================================
Função-------------: AFIN040D
Autor--------------: Julio de Paula Paz
Data da Criacao----: 15/09/2025
Descrição----------: Lê os dados gravados para o Fechamento Financeiro e carrega as tabelas temporárias.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/
Static Function AFIN040D(_cGrid,_cFilter)

    Local _aCab1       := {}                             As Array
    Local _aCab2       := {}                             As Array
    Local _aItem1A     := {}                             As Array
    Local _aItem2A     := {}                             As Array
    Local _aItem1B     := {}                             As Array
    Local _aItem2B     := {}                             As Array
    Local _aItem1C     := {}                             As Array
    Local _aItem2C     := {}                             As Array
    Local _aItem1D     := {}                             As Array
    Local _aItem2D     := {}                             As Array
    Local _aItem1E     := {}                             As Array
    Local _aItem2E     := {}                             As Array
    Local _aItem1F     := {}                             As Array
    Local _aItem2F     := {}                             As Array
    Local _aItem1G     := {}                             As Array
    Local _aItem2G     := {}                             As Array
    Local _aItem1H     := {}                             As Array
    Local _aItem2H     := {}                             As Array
    Local _aItem1I     := {}                             As Array
    Local _aItem2I     := {}                             As Array
    Local _aItem1J     := {}                             As Array
    Local _aItem2J     := {}                             As Array
    Local _aItem1K     := {}                             As Array
    Local _aItem2K     := {}                             As Array
    Local _aItem1L     := {}                             As Array
    Local _aItem2L     := {}                             As Array
    Local _aItem1M     := {}                             As Array
    Local _aItem2M     := {}                             As Array
    Local _aItem1N     := {}                             As Array
    Local _aItem2N     := {}                             As Array
    Local _aItem1O     := {}                             As Array
    Local _aItem2O     := {}                             As Array
    Local _aItem1P     := {}                             As Array
    Local _aItem2P     := {}                             As Array
    Local _aItem1Q     := {}                             As Array
    Local _aItem2Q     := {}                             As Array
    Local _aItem1R     := {}                             As Array
    Local _aItem2R     := {}                             As Array
    Local _aItem1S     := {}                             As Array
    Local _aItem2S     := {}                             As Array
    Local _cQry        := ""                             As Characater
    Local _cQry2       := ""                             As Characater
    Local _cFilTit     := ""                             As Characater
    Local _nTotRCab    := 0                              As Numeric
    Local _nTotRDet    := 0                              As Numeric
    Local _lTemDados   := .F.                            As Logical
    Local _lTdAbas     := .F.                            As Loical

    Default _cFilter := ""
    Default _cGrid   := ""

    Begin Sequence 

    AFIN040G(@_aCab1,@_aCab2)  

    If !Empty(MV_PAR03)
        _cFilTit := FORMATIN(Alltrim(MV_PAR03),";")
    Endif  

     If _cAbas == "00" .And. !Empty(_cFilter)
        _cAbas := _cGrid
        _lTdAbas := .T.
    Endif
        
    ProcRegua(0)

    //============================================
    // 01-Tudo com Emissão Dentro do Mês = A
    //============================================
    If _cAbas == "00" .Or. _cAbas == "01"
        IncProc("Gerando dados: 01-Tudo com Emissão Dentro do Mês...")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '01' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '01' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS, ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_A")
        DBSelectArea("QRYCAB_A")

        Count To _nTotRCab
        QRYCAB_A->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_A")
        DBSelectArea("QRYDET_A")
        
        Count To _nTotRDet
        QRYDET_A->(DbGotop())
        
        _lTemDados := .F.
        ProcRegua(_nTotRCab)

        Do While ! QRYCAB_A->(Eof())
            IncProc("Lendo dados Sintetico -01-Tudo com Emissão Dentro do Mês")
            TRBCAB_A->(DbAppend())
            TRBCAB_A->ZCA_VISAO  := QRYCAB_A->ZCA_VISAO	        // Item Visao
            TRBCAB_A->ZCA_DESVIS := QRYCAB_A->ZCA_DESVIS        // Descr.Visao
            TRBCAB_A->ZCA_FILVIS := QRYCAB_A->ZCA_FILVIS        // Filial Visao
            TRBCAB_A->ZCA_VALOR  := QRYCAB_A->ZCA_VALOR	        // Valor Filial
            TRBCAB_A->ZCA_VERSAO := QRYCAB_A->ZCA_VERSAO        // Versão
            TRBCAB_A->ZCA_MESANO := QRYCAB_A->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_A->ZCA_DTEMIS := StoD(QRYCAB_A->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_A->ZCA_HREMIS := QRYCAB_A->ZCA_HREMIS        // Hora Emissao
            TRBCAB_A->ZCA_USUARI := QRYCAB_A->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1A, {QRYCAB_A->ZCA_VISAO,;        // Item Visao
                QRYCAB_A->ZCA_DESVIS,;       // Descr.Visao
                QRYCAB_A->ZCA_FILVIS,;       // Filial Visao
                QRYCAB_A->ZCA_VALOR,;        // Valor Filial
                QRYCAB_A->ZCA_VERSAO,;       // Versão
                QRYCAB_A->ZCA_MESANO,;       // Mês/Ano Emis
                StoD(QRYCAB_A->ZCA_DTEMIS),; // Data Emissao
                QRYCAB_A->ZCA_HREMIS,;       // Hora Emissao
                QRYCAB_A->ZCA_USUARI})       // Usuario Fech
            
            _lTemDados := .T.
            QRYCAB_A->(DbSkip())         
        EndDo

        If _lTemDados
            AAdd(_aCabec,{"01-Emissão no Mês-Sinte",_aCab1})
            AAdd(_aCabec,{"01-Emissão no Mês-Anali",_aCab2})
            AAdd(_aItem,_aItem1A)
        Endif 
        
        If ! _lTemDados 
            TRBCAB_A->(DbAppend())
        EndIf

        _lTemDados := .F.
        ProcRegua(_nTotRDet)

        Do While ! QRYDET_A->(Eof())
            IncProc("Lendo Dados Analítico - 01-Tudo com Emissão Dentro do Mês")
            TRBDET_A->(DbAppend())
            TRBDET_A->ZCB_VISAO  := QRYDET_A->ZCB_VISAO	       //	Item Visao
            TRBDET_A->ZCB_FILVIS := QRYDET_A->ZCB_FILVIS       //	Filial Visao
            TRBDET_A->ZCB_VERSAO := QRYDET_A->ZCB_VERSAO       //	Versão
            TRBDET_A->ZCB_MESANO := QRYDET_A->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_A->ZCB_DTEMIS := StoD(QRYDET_A->ZCB_DTEMIS) //	Data Emissao
            TRBDET_A->ZCB_HREMIS := QRYDET_A->ZCB_HREMIS       //	Hora Emissao
            TRBDET_A->ZCB_USUARI := QRYDET_A->ZCB_USUARI       //	Usuario Fech
            TRBDET_A->ZCB_NUMTIT := QRYDET_A->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_A->ZCB_PREFIX := QRYDET_A->ZCB_PREFIX       //	Prefixo     
            TRBDET_A->ZCB_PARCEL := QRYDET_A->ZCB_PARCEL       //	Parcerla
            TRBDET_A->ZCB_TIPO   := QRYDET_A->ZCB_TIPO         //	Tipo
            TRBDET_A->ZCB_CLIENT := QRYDET_A->ZCB_CLIENT       //	Cliente 
            TRBDET_A->ZCB_LOJA   := QRYDET_A->ZCB_LOJA         //	Loja
            TRBDET_A->ZCB_NOMCLI := QRYDET_A->ZCB_NOMCLI       //	Nome
            TRBDET_A->ZCB_VALOR  := QRYDET_A->ZCB_VALOR        //	Valor
            TRBDET_A->ZCB_EMISSA := StoD(QRYDET_A->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2A, {QRYDET_A->ZCB_VISAO,;        // Item Visao
                QRYDET_A->ZCB_FILVIS,;       // Filial Visao
                QRYDET_A->ZCB_VERSAO,;       // Versão
                QRYDET_A->ZCB_MESANO,;       // Mês/Ano Emis
                StoD(QRYDET_A->ZCB_DTEMIS),; // Data Emissao
                QRYDET_A->ZCB_HREMIS,;       // Hora Emissao
                QRYDET_A->ZCB_USUARI,;       // Usuario Fech
                QRYDET_A->ZCB_NUMTIT,;       // No. Titulo
                QRYDET_A->ZCB_PREFIX,;       // Prefixo
                QRYDET_A->ZCB_PARCEL,;       // Parcela
                QRYDET_A->ZCB_TIPO,;         // Tipo
                QRYDET_A->ZCB_CLIENT,;       // Cliente
                QRYDET_A->ZCB_LOJA,;         // Loja
                QRYDET_A->ZCB_NOMCLI,;       // Nome
                QRYDET_A->ZCB_VALOR,;        // Valor
                StoD(QRYDET_A->ZCB_EMISSA)}) // Emissão 

            _lTemDados := .T. 
            QRYDET_A->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2A)
        Endif 

        If ! _lTemDados 
            TRBDET_A->(DbAppend())
        EndIf
    Endif     

    //============================================
    // 02-Faturamento Manual no Mês = B
    //============================================
    If _cAbas == "00" .Or. _cAbas == "02"
        IncProc("Gerando dados: 02-Faturamento Manual no Mês ")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '02' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '02' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS, ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_B")
        DBSelectArea("QRYCAB_B")
        
        Count To _nTotRCab
        QRYCAB_B->(DbGotop())
        
        MPSysOpenQuery( _cQry2 , "QRYDET_B")
        DBSelectArea("QRYDET_B")
        
        Count To _nTotRDet
        QRYDET_B->(DbGotop())

        _lTemDados := .F.

        Do While ! QRYCAB_B->(Eof())
            IncProc("Lendo dados Sintético - 02-Faturamento Manual no Mês")
            TRBCAB_B->(DbAppend())
            TRBCAB_B->ZCA_VISAO  := QRYCAB_B->ZCA_VISAO	        // Item Visao
            TRBCAB_B->ZCA_DESVIS := QRYCAB_B->ZCA_DESVIS        // Descr.Visao
            TRBCAB_B->ZCA_FILVIS := QRYCAB_B->ZCA_FILVIS        // Filial Visao
            TRBCAB_B->ZCA_VALOR  := QRYCAB_B->ZCA_VALOR	        // Valor Filial
            TRBCAB_B->ZCA_VERSAO := QRYCAB_B->ZCA_VERSAO        // Versão
            TRBCAB_B->ZCA_MESANO := QRYCAB_B->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_B->ZCA_DTEMIS := StoD(QRYCAB_B->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_B->ZCA_HREMIS := QRYCAB_B->ZCA_HREMIS        // Hora Emissao
            TRBCAB_B->ZCA_USUARI := QRYCAB_B->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1B, {QRYCAB_B->ZCA_VISAO,;    // Item Visao
                QRYCAB_B->ZCA_DESVIS,;              // Descr.Visao
                QRYCAB_B->ZCA_FILVIS,;              // Filial Visao
                QRYCAB_B->ZCA_VALOR,;               // Valor Filial
                QRYCAB_B->ZCA_VERSAO,;              // Versão
                QRYCAB_B->ZCA_MESANO,;              // Mês/Ano Emis
                StoD(QRYCAB_B->ZCA_DTEMIS),;        // Data Emissao 
                QRYCAB_B->ZCA_HREMIS,;              // Hora Emissao
                QRYCAB_B->ZCA_USUARI})              // Usuario Fech
            
            _lTemDados := .T. 
            QRYCAB_B->(DbSkip())         
        EndDo

        If _lTemDados
            AAdd(_aCabec,{"02-Fat. Manual no Mês Sint",_aCab1})
            AAdd(_aCabec,{"02-Fat. Manual no Mês Anal",_aCab2})
            AAdd(_aItem,_aItem1B)
        Endif 
        
        If ! _lTemDados 
            TRBCAB_B->(DbAppend())
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_B->(Eof())
            IncProc("Lendo dados Analítico - 02-Faturamento Manual no Mês")
            TRBDET_B->(DbAppend())
            TRBDET_B->ZCB_VISAO  := QRYDET_B->ZCB_VISAO	      //	Item Visao
            TRBDET_B->ZCB_FILVIS := QRYDET_B->ZCB_FILVIS       //	Filial Visao
            TRBDET_B->ZCB_VERSAO := QRYDET_B->ZCB_VERSAO       //	Versão
            TRBDET_B->ZCB_MESANO := QRYDET_B->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_B->ZCB_DTEMIS := StoD(QRYDET_B->ZCB_DTEMIS) //	Data Emissao
            TRBDET_B->ZCB_HREMIS := QRYDET_B->ZCB_HREMIS       //	Hora Emissao
            TRBDET_B->ZCB_USUARI := QRYDET_B->ZCB_USUARI       //	Usuario Fech
            TRBDET_B->ZCB_NUMTIT := QRYDET_B->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_B->ZCB_PREFIX := QRYDET_B->ZCB_PREFIX       //	Prefixo     
            TRBDET_B->ZCB_PARCEL := QRYDET_B->ZCB_PARCEL       //	Parcerla
            TRBDET_B->ZCB_TIPO   := QRYDET_B->ZCB_TIPO         //	Tipo
            TRBDET_B->ZCB_CLIENT := QRYDET_B->ZCB_CLIENT       //	Cliente 
            TRBDET_B->ZCB_LOJA   := QRYDET_B->ZCB_LOJA         //	Loja
            TRBDET_B->ZCB_NOMCLI := QRYDET_B->ZCB_NOMCLI       //	Nome
            TRBDET_B->ZCB_VALOR  := QRYDET_B->ZCB_VALOR        //	Valor
            TRBDET_B->ZCB_EMISSA := StoD(QRYDET_B->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2B, {QRYDET_B->ZCB_VISAO,;    // Item Visao
                QRYDET_B->ZCB_FILVIS,;              // Filial Visao
                QRYDET_B->ZCB_VERSAO,;              // Versão
                QRYDET_B->ZCB_MESANO,;              // Mês/Ano Emis
                StoD(QRYDET_B->ZCB_DTEMIS),;        // Data Emissao
                QRYDET_B->ZCB_HREMIS,;              // Hora Emissao
                QRYDET_B->ZCB_USUARI,;              // Usuario Fech
                QRYDET_B->ZCB_NUMTIT,;              // No. Titulo
                QRYDET_B->ZCB_PREFIX,;              // Prefixo
                QRYDET_B->ZCB_PARCEL,;              // Parcela
                QRYDET_B->ZCB_TIPO,;                // Tipo
                QRYDET_B->ZCB_CLIENT,;              // Cliente
                QRYDET_B->ZCB_LOJA,;                // Loja
                QRYDET_B->ZCB_NOMCLI,;              // Nome
                QRYDET_B->ZCB_VALOR,;               // Valor
                StoD(QRYDET_B->ZCB_EMISSA)})        // Emissão

            _lTemDados := .T. 
            QRYDET_B->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2B)
        Endif 

        If ! _lTemDados 
            TRBDET_B->(DbAppend())
        EndIf
    EndIf     

    //============================================
    // 03-Recebimento de Crédito no Mês = C
    //============================================
    If _cAbas == "00" .Or. _cAbas == "03"
        IncProc("Gerando dados: 03-Recebimento de Crédito no Mês ")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '03' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '03' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS, ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_C")
        DBSelectArea("QRYCAB_C")
        
        Count To _nTotRCab
        QRYCAB_C->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_C")
        DBSelectArea("QRYDET_C")
        
        Count To _nTotRDet
        QRYDET_C->(DbGotop())
        
        _lTemDados := .F.

        Do While ! QRYCAB_C->(Eof())
            IncProc("Lendo dados Sintético - 03-Recebimento de Crédito no Mês") 
            TRBCAB_C->(DbAppend())
            TRBCAB_C->ZCA_VISAO  := QRYCAB_C->ZCA_VISAO	        // Item Visao
            TRBCAB_C->ZCA_DESVIS := QRYCAB_C->ZCA_DESVIS        // Descr.Visao
            TRBCAB_C->ZCA_FILVIS := QRYCAB_C->ZCA_FILVIS        // Filial Visao
            TRBCAB_C->ZCA_VALOR  := QRYCAB_C->ZCA_VALOR	        // Valor Filial
            TRBCAB_C->ZCA_VERSAO := QRYCAB_C->ZCA_VERSAO        // Versão
            TRBCAB_C->ZCA_MESANO := QRYCAB_C->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_C->ZCA_DTEMIS := StoD(QRYCAB_C->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_C->ZCA_HREMIS := QRYCAB_C->ZCA_HREMIS        // Hora Emissao
            TRBCAB_C->ZCA_USUARI := QRYCAB_C->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1C, {QRYCAB_C->ZCA_VISAO,;    // Item Visao
                QRYCAB_C->ZCA_DESVIS,;              // Descr.Visao
                QRYCAB_C->ZCA_FILVIS,;              // Filial Visao
                QRYCAB_C->ZCA_VALOR,;               // Valor Filial
                QRYCAB_C->ZCA_VERSAO,;              // Versão
                QRYCAB_C->ZCA_MESANO,;              // Mês/Ano Emis
                StoD(QRYCAB_C->ZCA_DTEMIS),;        // Data Emissao 
                QRYCAB_C->ZCA_HREMIS,;              // Hora Emissao
                QRYCAB_C->ZCA_USUARI})              // Usuario Fech

            _lTemDados := .T. 
            QRYCAB_C->(DbSkip())         
        EndDo

        If _lTemDados
            AAdd(_aCabec,{"03-Recbto Créd no Mês Sint",_aCab1})
            AAdd(_aCabec,{"03-Recbto Créd no Mês Anali",_aCab2})
            AAdd(_aItem,_aItem1C)
        Endif 

        If ! _lTemDados 
            TRBCAB_C->(DbAppend())
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_C->(Eof())
            IncProc("Lendo dados Analítico - 03-Recebimento de Crédito no Mês")      
            TRBDET_C->(DbAppend())
            TRBDET_C->ZCB_VISAO  := QRYDET_C->ZCB_VISAO	       //	Item Visao
            TRBDET_C->ZCB_FILVIS := QRYDET_C->ZCB_FILVIS       //	Filial Visao
            TRBDET_C->ZCB_VERSAO := QRYDET_C->ZCB_VERSAO       //	Versão
            TRBDET_C->ZCB_MESANO := QRYDET_C->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_C->ZCB_DTEMIS := StoD(QRYDET_C->ZCB_DTEMIS) //	Data Emissao
            TRBDET_C->ZCB_HREMIS := QRYDET_C->ZCB_HREMIS       //	Hora Emissao
            TRBDET_C->ZCB_USUARI := QRYDET_C->ZCB_USUARI       //	Usuario Fech
            TRBDET_C->ZCB_NUMTIT := QRYDET_C->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_C->ZCB_PREFIX := QRYDET_C->ZCB_PREFIX       //	Prefixo     
            TRBDET_C->ZCB_PARCEL := QRYDET_C->ZCB_PARCEL       //	Parcerla
            TRBDET_C->ZCB_TIPO   := QRYDET_C->ZCB_TIPO         //	Tipo
            TRBDET_C->ZCB_CLIENT := QRYDET_C->ZCB_CLIENT       //	Cliente 
            TRBDET_C->ZCB_LOJA   := QRYDET_C->ZCB_LOJA         //	Loja
            TRBDET_C->ZCB_NOMCLI := QRYDET_C->ZCB_NOMCLI       //	Nome
            TRBDET_C->ZCB_VALOR  := QRYDET_C->ZCB_VALOR        //	Valor
            TRBDET_C->ZCB_EMISSA := StoD(QRYDET_C->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2C, {QRYDET_C->ZCB_VISAO,;    // Item Visao
                QRYDET_C->ZCB_FILVIS,;              // Filial Visao
                QRYDET_C->ZCB_VERSAO,;              // Versão
                QRYDET_C->ZCB_MESANO,;              // Mês/Ano Emis
                StoD(QRYDET_C->ZCB_DTEMIS),;        // Data Emissao 
                QRYDET_C->ZCB_HREMIS,;              // Hora Emissao
                QRYDET_C->ZCB_USUARI,;              // Usuario Fech
                QRYDET_C->ZCB_NUMTIT,;              // No. Titulo
                QRYDET_C->ZCB_PREFIX,;              // Prefixo
                QRYDET_C->ZCB_PARCEL,;              // Parcela
                QRYDET_C->ZCB_TIPO,;                // Tipo
                QRYDET_C->ZCB_CLIENT,;              // Cliente
                QRYDET_C->ZCB_LOJA,;                // Loja
                QRYDET_C->ZCB_NOMCLI,;              // Nome
                QRYDET_C->ZCB_VALOR,;               // Valor
                StoD(QRYDET_C->ZCB_EMISSA)})        // Emissão 

            _lTemDados := .T. 
            QRYDET_C->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2C)
        Endif 

        If ! _lTemDados 
            TRBDET_C->(DbAppend())
        EndIf 
    EndIf

    //============================================
    // 04-Desmembramento no Mês = D
    //============================================
    If _cAbas == "00" .Or. _cAbas == "04"
        IncProc("Gerando dados: 04-Desmembramento no Mês ")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '04' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '04' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS, ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_D")
        DBSelectArea("QRYCAB_D")
        
        Count To _nTotRCab
        QRYCAB_D->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_D")
        DBSelectArea("QRYDET_D")
        
        Count To _nTotRDet
        QRYDET_D->(DbGotop())

        _lTemDados := .F.

        Do While ! QRYCAB_D->(Eof())
            IncProc("Lendo dados Sintético - 04-Desmembramento no Mês")
            TRBCAB_D->(DbAppend())
            TRBCAB_D->ZCA_VISAO  := QRYCAB_D->ZCA_VISAO	        // Item Visao
            TRBCAB_D->ZCA_DESVIS := QRYCAB_D->ZCA_DESVIS        // Descr.Visao
            TRBCAB_D->ZCA_FILVIS := QRYCAB_D->ZCA_FILVIS        // Filial Visao
            TRBCAB_D->ZCA_VALOR  := QRYCAB_D->ZCA_VALOR	        // Valor Filial
            TRBCAB_D->ZCA_VERSAO := QRYCAB_D->ZCA_VERSAO        // Versão
            TRBCAB_D->ZCA_MESANO := QRYCAB_D->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_D->ZCA_DTEMIS := StoD(QRYCAB_D->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_D->ZCA_HREMIS := QRYCAB_D->ZCA_HREMIS        // Hora Emissao
            TRBCAB_D->ZCA_USUARI := QRYCAB_D->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1D, {QRYCAB_D->ZCA_VISAO,;    // Item Visao
                QRYCAB_D->ZCA_DESVIS,;              // Descr.Visao
                QRYCAB_D->ZCA_FILVIS,;              // Filial Visao
                QRYCAB_D->ZCA_VALOR,;               // Valor Filial
                QRYCAB_D->ZCA_VERSAO,;              // Versão
                QRYCAB_D->ZCA_MESANO,;              // Mês/Ano Emis
                StoD(QRYCAB_D->ZCA_DTEMIS),;        // Data Emissao 
                QRYCAB_D->ZCA_HREMIS,;              // Hora Emissao
                QRYCAB_D->ZCA_USUARI})              // Usuario Fech

            If _lTemDados
                AAdd(_aCabec,{"04-Desmembramento Mês Sint",_aCab1})
                AAdd(_aCabec,{"04-Desmembramento Mês Anal",_aCab2})
                AAdd(_aItem,_aItem1D)
            Endif 

            _lTemDados := .T. 
            QRYCAB_D->(DbSkip())         
        EndDo 

        If ! _lTemDados 
            TRBCAB_D->(DbAppend())
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_D->(Eof())
            IncProc("Lendo dados Analítico - 04-Desmembramento no Mês")
            TRBDET_D->(DbAppend())
            TRBDET_D->ZCB_VISAO  := QRYDET_D->ZCB_VISAO	       //	Item Visao
            TRBDET_D->ZCB_FILVIS := QRYDET_D->ZCB_FILVIS       //	Filial Visao
            TRBDET_D->ZCB_VERSAO := QRYDET_D->ZCB_VERSAO       //	Versão
            TRBDET_D->ZCB_MESANO := QRYDET_D->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_D->ZCB_DTEMIS := StoD(QRYDET_D->ZCB_DTEMIS) //	Data Emissao
            TRBDET_D->ZCB_HREMIS := QRYDET_D->ZCB_HREMIS       //	Hora Emissao
            TRBDET_D->ZCB_USUARI := QRYDET_D->ZCB_USUARI       //	Usuario Fech
            TRBDET_D->ZCB_NUMTIT := QRYDET_D->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_D->ZCB_PREFIX := QRYDET_D->ZCB_PREFIX       //	Prefixo     
            TRBDET_D->ZCB_PARCEL := QRYDET_D->ZCB_PARCEL       //	Parcerla
            TRBDET_D->ZCB_TIPO   := QRYDET_D->ZCB_TIPO         //	Tipo
            TRBDET_D->ZCB_CLIENT := QRYDET_D->ZCB_CLIENT       //	Cliente 
            TRBDET_D->ZCB_LOJA   := QRYDET_D->ZCB_LOJA         //	Loja
            TRBDET_D->ZCB_NOMCLI := QRYDET_D->ZCB_NOMCLI       //	Nome
            TRBDET_D->ZCB_VALOR  := QRYDET_D->ZCB_VALOR        //	Valor
            TRBDET_D->ZCB_EMISSA := StoD(QRYDET_D->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2D, {QRYDET_D->ZCB_VISAO,;    // Item Visao
                QRYDET_D->ZCB_FILVIS,;   // Filial Visao
                QRYDET_D->ZCB_VERSAO,;   // Versão
                QRYDET_D->ZCB_MESANO,;   // Mês/Ano Emis
                StoD(QRYDET_D->ZCB_DTEMIS),; // Data Emissao 
                QRYDET_D->ZCB_HREMIS,;   // Hora Emissao
                QRYDET_D->ZCB_USUARI,;   // Usuario Fech
                QRYDET_D->ZCB_NUMTIT,;   // No. Titulo
                QRYDET_D->ZCB_PREFIX,;   // Prefixo
                QRYDET_D->ZCB_PARCEL,;   // Parcela
                QRYDET_D->ZCB_TIPO,;     // Tipo
                QRYDET_D->ZCB_CLIENT,;   // Cliente
                QRYDET_D->ZCB_LOJA,;     // Loja
                QRYDET_D->ZCB_NOMCLI,;   // Nome
                QRYDET_D->ZCB_VALOR,;    // Valor
                StoD(QRYDET_D->ZCB_EMISSA)})  // Emissão 

            _lTemDados := .T. 
            QRYDET_D->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2D)
        Endif

        If ! _lTemDados 
            TRBDET_D->(DbAppend())
        EndIf
    EndIf     

    //============================================
    // 05-Totalizador-Superior 4 meses = E
    //============================================
    If _cAbas == "00" .Or. _cAbas == "05"
        IncProc("Gerando dados: 05-Totalizador-Superior 4 meses ")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '05' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '05' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS, ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_E")
        DBSelectArea("QRYCAB_E")
        
        Count To _nTotRCab
        QRYCAB_E->(DbGotop())
        
        MPSysOpenQuery( _cQry2 , "QRYDET_E")
        DBSelectArea("QRYDET_E")
        
        Count To _nTotRDet
        QRYDET_E->(DbGotop())

        _lTemDados := .F.

        Do While ! QRYCAB_E->(Eof())
            IncProc("Lendo dados Sintético - 05-Totalizador-Superior 4 meses")
            TRBCAB_E->(DbAppend())
            TRBCAB_E->ZCA_VISAO  := QRYCAB_E->ZCA_VISAO	        // Item Visao
            TRBCAB_E->ZCA_DESVIS := QRYCAB_E->ZCA_DESVIS        // Descr.Visao
            TRBCAB_E->ZCA_FILVIS := QRYCAB_E->ZCA_FILVIS        // Filial Visao
            TRBCAB_E->ZCA_VALOR  := QRYCAB_E->ZCA_VALOR	        // Valor Filial
            TRBCAB_E->ZCA_VERSAO := QRYCAB_E->ZCA_VERSAO        // Versão
            TRBCAB_E->ZCA_MESANO := QRYCAB_E->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_E->ZCA_DTEMIS := StoD(QRYCAB_E->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_E->ZCA_HREMIS := QRYCAB_E->ZCA_HREMIS        // Hora Emissao
            TRBCAB_E->ZCA_USUARI := QRYCAB_E->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1E, {QRYCAB_E->ZCA_VISAO,; // Item Visao
                QRYCAB_E->ZCA_DESVIS,;          // Descr.Visao
                QRYCAB_E->ZCA_FILVIS,;          // Filial Visao
                QRYCAB_E->ZCA_VALOR,;           // Valor Filial
                QRYCAB_E->ZCA_VERSAO,;          // Versão
                QRYCAB_E->ZCA_MESANO,;          // Mês/Ano Emis
                StoD(QRYCAB_E->ZCA_DTEMIS),;    // Data Emissao 
                QRYCAB_E->ZCA_HREMIS,;          // Hora Emissao
                QRYCAB_E->ZCA_USUARI})          // Usuario Fech

            _lTemDados := .T. 
            QRYCAB_E->(DbSkip())         
        EndDo

        If _lTemDados
            AAdd(_aCabec,{"05-Total Sup. 4 Meses Sint",_aCab1})
            AAdd(_aCabec,{"05-Total Sup. 4 Meses Anal",_aCab2})
            AAdd(_aItem,_aItem1E)
        Endif 

        If ! _lTemDados 
            TRBCAB_E->(DbAppend())
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_E->(Eof())
            IncProc("Lendo dados Analítico - 05-Totalizador-Superior 4 meses")
            TRBDET_E->(DbAppend())
            TRBDET_E->ZCB_VISAO  := QRYDET_E->ZCB_VISAO	       //	Item Visao
            TRBDET_E->ZCB_FILVIS := QRYDET_E->ZCB_FILVIS       //	Filial Visao
            TRBDET_E->ZCB_VERSAO := QRYDET_E->ZCB_VERSAO       //	Versão
            TRBDET_E->ZCB_MESANO := QRYDET_E->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_E->ZCB_DTEMIS := StoD(QRYDET_E->ZCB_DTEMIS) //	Data Emissao
            TRBDET_E->ZCB_HREMIS := QRYDET_E->ZCB_HREMIS       //	Hora Emissao
            TRBDET_E->ZCB_USUARI := QRYDET_E->ZCB_USUARI       //	Usuario Fech
            TRBDET_E->ZCB_NUMTIT := QRYDET_E->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_E->ZCB_PREFIX := QRYDET_E->ZCB_PREFIX       //	Prefixo     
            TRBDET_E->ZCB_PARCEL := QRYDET_E->ZCB_PARCEL       //	Parcerla
            TRBDET_E->ZCB_TIPO   := QRYDET_E->ZCB_TIPO         //	Tipo
            TRBDET_E->ZCB_CLIENT := QRYDET_E->ZCB_CLIENT       //	Cliente 
            TRBDET_E->ZCB_LOJA   := QRYDET_E->ZCB_LOJA         //	Loja
            TRBDET_E->ZCB_NOMCLI := QRYDET_E->ZCB_NOMCLI       //	Nome
            TRBDET_E->ZCB_VALOR  := QRYDET_E->ZCB_VALOR        //	Valor
            TRBDET_E->ZCB_EMISSA := StoD(QRYDET_E->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2E, {QRYDET_E->ZCB_VISAO,;    // Item Visao
                QRYDET_E->ZCB_FILVIS,;              // Filial Visao
                QRYDET_E->ZCB_VERSAO,;              // Versão
                QRYDET_E->ZCB_MESANO,;              // Mês/Ano Emis
                StoD(QRYDET_E->ZCB_DTEMIS),;        // Data Emissao 
                QRYDET_E->ZCB_HREMIS,;              // Hora Emissao
                QRYDET_E->ZCB_USUARI,;              // Usuario Fech
                QRYDET_E->ZCB_NUMTIT,;              // No. Titulo
                QRYDET_E->ZCB_PREFIX,;              // Prefixo
                QRYDET_E->ZCB_PARCEL,;              // Parcela
                QRYDET_E->ZCB_TIPO,;                // Tipo
                QRYDET_E->ZCB_CLIENT,;              // Cliente
                QRYDET_E->ZCB_LOJA,;                // Loja
                QRYDET_E->ZCB_NOMCLI,;              // Nome
                QRYDET_E->ZCB_VALOR,;               // Valor
                StoD(QRYDET_E->ZCB_EMISSA)})        // Emissão 

            _lTemDados := .T. 
            QRYDET_E->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2E)
        Endif

        If ! _lTemDados 
            TRBDET_E->(DbAppend())
        EndIf 
    EndIf

    //===================================================
    // 06-Totalizador-Faturamentos do 4º mês anterior = F
    //===================================================
    If _cAbas == "00" .Or. _cAbas == "06"
        IncProc("Gerando dados: 06-Totalizador-Faturamentos do 4º mês anterior ")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '06' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '06' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS, ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_F")
        DBSelectArea("QRYCAB_F")
        
        Count To _nTotRCab
        QRYCAB_F->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_F")
        DBSelectArea("QRYDET_F")
        
        Count To _nTotRDet
        QRYDET_F->(DbGotop())

        _lTemDados := .F.

        Do While ! QRYCAB_F->(Eof())
            IncProc("Lendo dados Sintético - 06-Totalizador-Faturamentos do 4º mês anterior")
            TRBCAB_F->(DbAppend())
            //TRBCAB_F->ZCA_FILIAL := QRYCAB_F->ZCA_FILIAL      // Filial
            TRBCAB_F->ZCA_VISAO  := QRYCAB_F->ZCA_VISAO	        // Item Visao
            TRBCAB_F->ZCA_DESVIS := QRYCAB_F->ZCA_DESVIS        // Descr.Visao
            TRBCAB_F->ZCA_FILVIS := QRYCAB_F->ZCA_FILVIS        // Filial Visao
            TRBCAB_F->ZCA_VALOR  := QRYCAB_F->ZCA_VALOR	        // Valor Filial
            TRBCAB_F->ZCA_VERSAO := QRYCAB_F->ZCA_VERSAO        // Versão
            TRBCAB_F->ZCA_MESANO := QRYCAB_F->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_F->ZCA_DTEMIS := StoD(QRYCAB_F->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_F->ZCA_HREMIS := QRYCAB_F->ZCA_HREMIS        // Hora Emissao
            TRBCAB_F->ZCA_USUARI := QRYCAB_F->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1F, {QRYCAB_F->ZCA_VISAO,;    // Item Visao
                QRYCAB_F->ZCA_DESVIS,;              // Descr.Visao
                QRYCAB_F->ZCA_FILVIS,;              // Filial Visao
                QRYCAB_F->ZCA_VALOR,;               // Valor Filial
                QRYCAB_F->ZCA_VERSAO,;              // Versão
                QRYCAB_F->ZCA_MESANO,;              // Mês/Ano Emis
                StoD(QRYCAB_F->ZCA_DTEMIS),;        // Data Emissao 
                QRYCAB_F->ZCA_HREMIS,;              // Hora Emissao
                QRYCAB_F->ZCA_USUARI})              // Usuario Fech

            _lTemDados := .T. 
            QRYCAB_F->(DbSkip())         
        EndDo

        If _lTemDados
            AAdd(_aCabec,{"06-Tot. Fat. 4º Mês Ant Sint",_aCab1})
            AAdd(_aCabec,{"06-Tot. Fat. 4º Mês Ant Anal",_aCab2})
            AAdd(_aItem,_aItem1F)
        Endif

        If ! _lTemDados 
            TRBCAB_F->(DbAppend())
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_F->(Eof())
            IncProc("Lendo dados Analítico - 06-Totalizador-Faturamentos do 4º mês anterior")
            TRBDET_F->(DbAppend())
            //TRBDET_F->ZCB_FILIAL := QRYDET_F->ZCB_FILIAL     //	Filial
            TRBDET_F->ZCB_VISAO  := QRYDET_F->ZCB_VISAO	       //	Item Visao
            TRBDET_F->ZCB_FILVIS := QRYDET_F->ZCB_FILVIS       //	Filial Visao
            TRBDET_F->ZCB_VERSAO := QRYDET_F->ZCB_VERSAO       //	Versão
            TRBDET_F->ZCB_MESANO := QRYDET_F->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_F->ZCB_DTEMIS := StoD(QRYDET_F->ZCB_DTEMIS) //	Data Emissao
            TRBDET_F->ZCB_HREMIS := QRYDET_F->ZCB_HREMIS       //	Hora Emissao
            TRBDET_F->ZCB_USUARI := QRYDET_F->ZCB_USUARI       //	Usuario Fech
            TRBDET_F->ZCB_NUMTIT := QRYDET_F->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_F->ZCB_PREFIX := QRYDET_F->ZCB_PREFIX       //	Prefixo     
            TRBDET_F->ZCB_PARCEL := QRYDET_F->ZCB_PARCEL       //	Parcerla
            TRBDET_F->ZCB_TIPO   := QRYDET_F->ZCB_TIPO         //	Tipo
            TRBDET_F->ZCB_CLIENT := QRYDET_F->ZCB_CLIENT       //	Cliente 
            TRBDET_F->ZCB_LOJA   := QRYDET_F->ZCB_LOJA         //	Loja
            TRBDET_F->ZCB_NOMCLI := QRYDET_F->ZCB_NOMCLI       //	Nome
            TRBDET_F->ZCB_VALOR  := QRYDET_F->ZCB_VALOR        //	Valor
            TRBDET_F->ZCB_EMISSA := StoD(QRYDET_F->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2F, {QRYDET_F->ZCB_VISAO,;    // Item Visao
                QRYDET_F->ZCB_FILVIS,;              // Filial Visao
                QRYDET_F->ZCB_VERSAO,;              // Versão
                QRYDET_F->ZCB_MESANO,;              // Mês/Ano Emis
                StoD(QRYDET_F->ZCB_DTEMIS),;        // Data Emissao 
                QRYDET_F->ZCB_HREMIS,;              // Hora Emissao
                QRYDET_F->ZCB_USUARI,;              // Usuario Fech
                QRYDET_F->ZCB_NUMTIT,;              // No. Titulo
                QRYDET_F->ZCB_PREFIX,;              // Prefixo
                QRYDET_F->ZCB_PARCEL,;              // Parcela
                QRYDET_F->ZCB_TIPO,;                // Tipo
                QRYDET_F->ZCB_CLIENT,;              // Cliente
                QRYDET_F->ZCB_LOJA,;                // Loja
                QRYDET_F->ZCB_NOMCLI,;              // Nome
                QRYDET_F->ZCB_VALOR,;               // Valor
                StoD(QRYDET_F->ZCB_EMISSA)})        // Emissão 

            _lTemDados := .T. 
            QRYDET_F->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2F)
        Endif 

        If ! _lTemDados 
            TRBDET_F->(DbAppend())
        EndIf 
    EndIf

    //============================================ 
    // 07-Totalizador–3o Mes Anterior = G
    //============================================
    If _cAbas == "00" .Or. _cAbas == "07"
        IncProc("Gerando dados: 07-Totalizador–3o Mes Anterior ")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '07' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '07' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS, ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_G")
        DBSelectArea("QRYCAB_G")
        
        Count To _nTotRCab
        QRYCAB_G->(DbGotop())
        
        MPSysOpenQuery( _cQry2 , "QRYDET_G")
        DBSelectArea("QRYDET_G")
        
        Count To _nTotRDet
        QRYDET_G->(DbGotop())

        _lTemDados := .F.

        Do While ! QRYCAB_G->(Eof())
            IncProc("Lendo dados Sintético - 07-Totalizador–3o Mes Anterior")
            TRBCAB_G->(DbAppend())
            TRBCAB_G->ZCA_VISAO  := QRYCAB_G->ZCA_VISAO	        // Item Visao
            TRBCAB_G->ZCA_DESVIS := QRYCAB_G->ZCA_DESVIS        // Descr.Visao
            TRBCAB_G->ZCA_FILVIS := QRYCAB_G->ZCA_FILVIS        // Filial Visao
            TRBCAB_G->ZCA_VALOR  := QRYCAB_G->ZCA_VALOR	        // Valor Filial
            TRBCAB_G->ZCA_VERSAO := QRYCAB_G->ZCA_VERSAO        // Versão
            TRBCAB_G->ZCA_MESANO := QRYCAB_G->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_G->ZCA_DTEMIS := StoD(QRYCAB_G->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_G->ZCA_HREMIS := QRYCAB_G->ZCA_HREMIS        // Hora Emissao
            TRBCAB_G->ZCA_USUARI := QRYCAB_G->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1G, {QRYCAB_G->ZCA_VISAO,;    // Item Visao
                            QRYCAB_G->ZCA_DESVIS,;              // Descr.Visao
                            QRYCAB_G->ZCA_FILVIS,;              // Filial Visao
                            QRYCAB_G->ZCA_VALOR,;               // Valor Filial
                            QRYCAB_G->ZCA_VERSAO,;              // Versão
                            QRYCAB_G->ZCA_MESANO,;              // Mês/Ano Emis
                            StoD(QRYCAB_G->ZCA_DTEMIS),;        // Data Emissao 
                            QRYCAB_G->ZCA_HREMIS,;              // Hora Emissao
                            QRYCAB_G->ZCA_USUARI})              // Usuario Fech

            _lTemDados := .T. 
            QRYCAB_G->(DbSkip())         
        EndDo 

        If _lTemDados
            AAdd(_aCabec,{"07-Total 3º Mês Ant Sint",_aCab1})
            AAdd(_aCabec,{"07-Total 3º Mês Ant Anal",_aCab2})
            AAdd(_aItem,_aItem1G)
        Endif 

        If ! _lTemDados 
            TRBCAB_G->(DbAppend())
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_G->(Eof())
            IncProc("Lendo dados Analítico - 07-Totalizador–3o Mes Anterior")
            TRBDET_G->(DbAppend())
            TRBDET_G->ZCB_VISAO  := QRYDET_G->ZCB_VISAO	       //	Item Visao
            TRBDET_G->ZCB_FILVIS := QRYDET_G->ZCB_FILVIS       //	Filial Visao
            TRBDET_G->ZCB_VERSAO := QRYDET_G->ZCB_VERSAO       //	Versão
            TRBDET_G->ZCB_MESANO := QRYDET_G->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_G->ZCB_DTEMIS := StoD(QRYDET_G->ZCB_DTEMIS) //	Data Emissao
            TRBDET_G->ZCB_HREMIS := QRYDET_G->ZCB_HREMIS       //	Hora Emissao
            TRBDET_G->ZCB_USUARI := QRYDET_G->ZCB_USUARI       //	Usuario Fech
            TRBDET_G->ZCB_NUMTIT := QRYDET_G->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_G->ZCB_PREFIX := QRYDET_G->ZCB_PREFIX       //	Prefixo     
            TRBDET_G->ZCB_PARCEL := QRYDET_G->ZCB_PARCEL       //	Parcerla
            TRBDET_G->ZCB_TIPO   := QRYDET_G->ZCB_TIPO         //	Tipo
            TRBDET_G->ZCB_CLIENT := QRYDET_G->ZCB_CLIENT       //	Cliente 
            TRBDET_G->ZCB_LOJA   := QRYDET_G->ZCB_LOJA         //	Loja
            TRBDET_G->ZCB_NOMCLI := QRYDET_G->ZCB_NOMCLI       //	Nome
            TRBDET_G->ZCB_VALOR  := QRYDET_G->ZCB_VALOR        //	Valor
            TRBDET_G->ZCB_EMISSA := StoD(QRYDET_G->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2G, {QRYDET_G->ZCB_VISAO,;    // Item Visao
                QRYDET_G->ZCB_FILVIS,;              // Filial Visao
                QRYDET_G->ZCB_VERSAO,;              // Versão
                QRYDET_G->ZCB_MESANO,;              // Mês/Ano Emis
                StoD(QRYDET_G->ZCB_DTEMIS),;        // Data Emissao 
                QRYDET_G->ZCB_HREMIS,;              // Hora Emissao
                QRYDET_G->ZCB_USUARI,;              // Usuario Fech
                QRYDET_G->ZCB_NUMTIT,;              // No. Titulo
                QRYDET_G->ZCB_PREFIX,;              // Prefixo
                QRYDET_G->ZCB_PARCEL,;              // Parcela
                QRYDET_G->ZCB_TIPO,;                // Tipo
                QRYDET_G->ZCB_CLIENT,;              // Cliente
                QRYDET_G->ZCB_LOJA,;                // Loja
                QRYDET_G->ZCB_NOMCLI,;              // Nome
                QRYDET_G->ZCB_VALOR,;               // Valor
                StoD(QRYDET_G->ZCB_EMISSA)})        // Emissão 

            _lTemDados := .T. 
            QRYDET_G->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2G)
        Endif 

        If ! _lTemDados 
            TRBDET_G->(DbAppend()) 
        EndIf 
    EndIf

    //============================================
    // 08-Totalizador-2o Mes Anterior = H
    //============================================
    If _cAbas == "00" .Or. _cAbas == "08"
        IncProc("Gerando dados: 08-Totalizador-2o Mes Anterior ")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '08' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '08' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS, ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_H")
        DBSelectArea("QRYCAB_H")
        
        Count To _nTotRCab
        QRYCAB_H->(DbGotop())
        
        MPSysOpenQuery( _cQry2 , "QRYDET_H")
        DBSelectArea("QRYDET_H")
        
        Count To _nTotRDet
        QRYDET_H->(DbGotop())
        
        _lTemDados := .F.

        Do While ! QRYCAB_H->(Eof())
            IncProc("Lendo dados Sintético - 08-Totalizador-2o Mes Anterior")
            TRBCAB_H->(DbAppend())
            TRBCAB_H->ZCA_VISAO  := QRYCAB_H->ZCA_VISAO	        // Item Visao
            TRBCAB_H->ZCA_DESVIS := QRYCAB_H->ZCA_DESVIS        // Descr.Visao
            TRBCAB_H->ZCA_FILVIS := QRYCAB_H->ZCA_FILVIS        // Filial Visao
            TRBCAB_H->ZCA_VALOR  := QRYCAB_H->ZCA_VALOR	        // Valor Filial
            TRBCAB_H->ZCA_VERSAO := QRYCAB_H->ZCA_VERSAO        // Versão
            TRBCAB_H->ZCA_MESANO := QRYCAB_H->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_H->ZCA_DTEMIS := StoD(QRYCAB_H->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_H->ZCA_HREMIS := QRYCAB_H->ZCA_HREMIS        // Hora Emissao
            TRBCAB_H->ZCA_USUARI := QRYCAB_H->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1H, {QRYCAB_H->ZCA_VISAO, ;     // Item-Visao
                QRYCAB_H->ZCA_DESVIS, ;    // Descr.Visao
                QRYCAB_H->ZCA_FILVIS, ;    // Filial-Visao
                QRYCAB_H->ZCA_VALOR, ;     // Valor-Filial
                QRYCAB_H->ZCA_VERSAO, ;    // Versão
                QRYCAB_H->ZCA_MESANO, ;    // Mês/Ano Emis
                StoD(QRYCAB_H->ZCA_DTEMIS), ; // Data Emissao 
                QRYCAB_H->ZCA_HREMIS, ;    // Hora Emissao
                QRYCAB_H->ZCA_USUARI })    // Usuario Fech

            _lTemDados := .T. 
            QRYCAB_H->(DbSkip())         
        EndDo

        If _lTemDados
            AAdd(_aCabec,{"08-Total 2º Mês Ant Sint",_aCab1})
            AAdd(_aCabec,{"08-Total 2º Mês Ant Anal",_aCab2})
            AAdd(_aItem,_aItem1H)
        Endif 

        If ! _lTemDados 
            TRBCAB_H->(DbAppend())
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_H->(Eof())
            IncProc("Lendo dados Analítico - 08-Totalizador-2o Mes Anterior")
            TRBDET_H->(DbAppend())
            TRBDET_H->ZCB_VISAO  := QRYDET_H->ZCB_VISAO	       //	Item Visao
            TRBDET_H->ZCB_FILVIS := QRYDET_H->ZCB_FILVIS       //	Filial Visao
            TRBDET_H->ZCB_VERSAO := QRYDET_H->ZCB_VERSAO       //	Versão
            TRBDET_H->ZCB_MESANO := QRYDET_H->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_H->ZCB_DTEMIS := StoD(QRYDET_H->ZCB_DTEMIS) //	Data Emissao
            TRBDET_H->ZCB_HREMIS := QRYDET_H->ZCB_HREMIS       //	Hora Emissao
            TRBDET_H->ZCB_USUARI := QRYDET_H->ZCB_USUARI       //	Usuario Fech
            TRBDET_H->ZCB_NUMTIT := QRYDET_H->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_H->ZCB_PREFIX := QRYDET_H->ZCB_PREFIX       //	Prefixo     
            TRBDET_H->ZCB_PARCEL := QRYDET_H->ZCB_PARCEL       //	Parcerla
            TRBDET_H->ZCB_TIPO   := QRYDET_H->ZCB_TIPO         //	Tipo
            TRBDET_H->ZCB_CLIENT := QRYDET_H->ZCB_CLIENT       //	Cliente 
            TRBDET_H->ZCB_LOJA   := QRYDET_H->ZCB_LOJA         //	Loja
            TRBDET_H->ZCB_NOMCLI := QRYDET_H->ZCB_NOMCLI       //	Nome
            TRBDET_H->ZCB_VALOR  := QRYDET_H->ZCB_VALOR        //	Valor
            TRBDET_H->ZCB_EMISSA := StoD(QRYDET_H->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2H, {QRYDET_H->ZCB_VISAO, ;         // Item Visao
                QRYDET_H->ZCB_FILVIS, ;        // Filial Visao
                QRYDET_H->ZCB_VERSAO, ;        // Versão
                QRYDET_H->ZCB_MESANO, ;        // Mês/Ano Emis
                StoD(QRYDET_H->ZCB_DTEMIS), ;  // Data Emissao 
                QRYDET_H->ZCB_HREMIS, ;        // Hora Emissao
                QRYDET_H->ZCB_USUARI, ;        // Usuario Fech
                QRYDET_H->ZCB_NUMTIT, ;        // No. Titulo
                QRYDET_H->ZCB_PREFIX, ;        // Prefixo
                QRYDET_H->ZCB_PARCEL, ;        // Parcela
                QRYDET_H->ZCB_TIPO, ;          // Tipo
                QRYDET_H->ZCB_CLIENT, ;        // Cliente
                QRYDET_H->ZCB_LOJA, ;          // Loja
                QRYDET_H->ZCB_NOMCLI, ;        // Nome
                QRYDET_H->ZCB_VALOR, ;         // Valor
                StoD(QRYDET_H->ZCB_EMISSA)})     // Emissão 

            _lTemDados := .T. 
            QRYDET_H->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2H)
        Endif 

        If ! _lTemDados 
            TRBDET_H->(DbAppend())
        EndIf 
    EndIf

    //============================================
    // 09-Totalizador-1o Mes Anterior = I
    //============================================
    If _cAbas == "00" .Or. _cAbas == "09"
        IncProc("Gerando dados: 09-Totalizador-1o Mes Anterior ")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '09' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '09' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS, ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_I")
        DBSelectArea("QRYCAB_I")
        
        Count To _nTotRCab
        QRYCAB_I->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_I")
        DBSelectArea("QRYDET_I")
        
        Count To _nTotRDet
        QRYDET_I->(DbGotop())

        _lTemDados := .F.

        Do While ! QRYCAB_I->(Eof())
            IncProc("Lendo dados Sintético - 09-Totalizador-1o Mes Anterior") 
            TRBCAB_I->(DbAppend())
            TRBCAB_I->ZCA_VISAO  := QRYCAB_I->ZCA_VISAO	        // Item Visao
            TRBCAB_I->ZCA_DESVIS := QRYCAB_I->ZCA_DESVIS        // Descr.Visao
            TRBCAB_I->ZCA_FILVIS := QRYCAB_I->ZCA_FILVIS        // Filial Visao
            TRBCAB_I->ZCA_VALOR  := QRYCAB_I->ZCA_VALOR	        // Valor Filial
            TRBCAB_I->ZCA_VERSAO := QRYCAB_I->ZCA_VERSAO        // Versão
            TRBCAB_I->ZCA_MESANO := QRYCAB_I->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_I->ZCA_DTEMIS := StoD(QRYCAB_I->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_I->ZCA_HREMIS := QRYCAB_I->ZCA_HREMIS        // Hora Emissao
            TRBCAB_I->ZCA_USUARI := QRYCAB_I->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1I, {QRYCAB_I->ZCA_VISAO,;        // Item Visao
                QRYCAB_I->ZCA_DESVIS,;                  // Descr. Visao
                QRYCAB_I->ZCA_FILVIS,;                  // Filial Visao
                QRYCAB_I->ZCA_VALOR,;                   // Valor Filial
                QRYCAB_I->ZCA_VERSAO,;                  // Versão
                QRYCAB_I->ZCA_MESANO,;                  // Mês/Ano Emis
                StoD(QRYCAB_I->ZCA_DTEMIS),;            // Data Emissao 
                QRYCAB_I->ZCA_HREMIS,;                  // Hora Emissao
                QRYCAB_I->ZCA_USUARI})                  // Usuario Fech

            _lTemDados := .T. 
            QRYCAB_I->(DbSkip())         
        EndDo

        If _lTemDados
            AAdd(_aCabec,{"09-Total 1º Mês Ant Sint",_aCab1})
            AAdd(_aCabec,{"09-Total 1º Mês Ant Anal",_aCab2})
            AAdd(_aItem,_aItem1I)
        Endif 

        If ! _lTemDados 
            TRBCAB_I->(DbAppend())
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_I->(Eof())
            IncProc("Lendo dados Analítico - 09-Totalizador-1o Mes Anterior") 
            TRBDET_I->(DbAppend())
            TRBDET_I->ZCB_VISAO  := QRYDET_I->ZCB_VISAO	       //	Item Visao
            TRBDET_I->ZCB_FILVIS := QRYDET_I->ZCB_FILVIS       //	Filial Visao
            TRBDET_I->ZCB_VERSAO := QRYDET_I->ZCB_VERSAO       //	Versão
            TRBDET_I->ZCB_MESANO := QRYDET_I->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_I->ZCB_DTEMIS := StoD(QRYDET_I->ZCB_DTEMIS) //	Data Emissao
            TRBDET_I->ZCB_HREMIS := QRYDET_I->ZCB_HREMIS       //	Hora Emissao
            TRBDET_I->ZCB_USUARI := QRYDET_I->ZCB_USUARI       //	Usuario Fech
            TRBDET_I->ZCB_NUMTIT := QRYDET_I->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_I->ZCB_PREFIX := QRYDET_I->ZCB_PREFIX       //	Prefixo     
            TRBDET_I->ZCB_PARCEL := QRYDET_I->ZCB_PARCEL       //	Parcerla
            TRBDET_I->ZCB_TIPO   := QRYDET_I->ZCB_TIPO         //	Tipo
            TRBDET_I->ZCB_CLIENT := QRYDET_I->ZCB_CLIENT       //	Cliente 
            TRBDET_I->ZCB_LOJA   := QRYDET_I->ZCB_LOJA         //	Loja
            TRBDET_I->ZCB_NOMCLI := QRYDET_I->ZCB_NOMCLI       //	Nome
            TRBDET_I->ZCB_VALOR  := QRYDET_I->ZCB_VALOR        //	Valor
            TRBDET_I->ZCB_EMISSA := StoD(QRYDET_I->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2I, { QRYDET_I->ZCB_VISAO, ;        // Item Visao
                QRYDET_I->ZCB_FILVIS, ;       // Filial Visao
                QRYDET_I->ZCB_VERSAO, ;       // Versão
                QRYDET_I->ZCB_MESANO, ;       // Mês/Ano Emis
                StoD(QRYDET_I->ZCB_DTEMIS), ; // Data Emissao 
                QRYDET_I->ZCB_HREMIS, ;       // Hora Emissao
                QRYDET_I->ZCB_USUARI, ;       // Usuario Fech
                QRYDET_I->ZCB_NUMTIT, ;       // No. Titulo
                QRYDET_I->ZCB_PREFIX, ;       // Prefixo
                QRYDET_I->ZCB_PARCEL, ;       // Parcela
                QRYDET_I->ZCB_TIPO, ;         // Tipo
                QRYDET_I->ZCB_CLIENT, ;       // Cliente
                QRYDET_I->ZCB_LOJA, ;         // Loja
                QRYDET_I->ZCB_NOMCLI, ;       // Nome
                QRYDET_I->ZCB_VALOR, ;        // Valor
                StoD(QRYDET_I->ZCB_EMISSA)})    // Emissão 

            _lTemDados := .T. 
            QRYDET_I->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2I)
        Endif 

        If ! _lTemDados 
            TRBDET_I->(DbAppend())
        EndIf 
    EndIf

    //============================================
    // 10-Totalizador–1o Mes Seguinte = J
    //============================================
    If _cAbas == "00" .Or. _cAbas == "10"
        IncProc("Gerando dados: 10-Totalizador–1o Mes Seguinte ")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '10' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '10' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS, ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_J")
        DBSelectArea("QRYCAB_J")
        
        Count To _nTotRCab
        QRYCAB_J->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_J")
        DBSelectArea("QRYDET_J")
        
        Count To _nTotRDet
        QRYDET_J->(DbGotop())

        _lTemDados := .F.

        Do While ! QRYCAB_J->(Eof())
            IncProc("Lendo dados Sintético - 10-Totalizador–1o Mes Seguinte")
            TRBCAB_J->(DbAppend())
            TRBCAB_J->ZCA_VISAO  := QRYCAB_J->ZCA_VISAO	        // Item Visao
            TRBCAB_J->ZCA_DESVIS := QRYCAB_J->ZCA_DESVIS        // Descr.Visao
            TRBCAB_J->ZCA_FILVIS := QRYCAB_J->ZCA_FILVIS        // Filial Visao
            TRBCAB_J->ZCA_VALOR  := QRYCAB_J->ZCA_VALOR	        // Valor Filial
            TRBCAB_J->ZCA_VERSAO := QRYCAB_J->ZCA_VERSAO        // Versão
            TRBCAB_J->ZCA_MESANO := QRYCAB_J->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_J->ZCA_DTEMIS := StoD(QRYCAB_J->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_J->ZCA_HREMIS := QRYCAB_J->ZCA_HREMIS        // Hora Emissao
            TRBCAB_J->ZCA_USUARI := QRYCAB_J->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1J, {QRYCAB_J->ZCA_VISAO,;        // Item Visao
                QRYCAB_J->ZCA_DESVIS,;                  // Descr. Visao
                QRYCAB_J->ZCA_FILVIS,;                  // Filial Visao
                QRYCAB_J->ZCA_VALOR,;                   // Valor Filial
                QRYCAB_J->ZCA_VERSAO,;                  // Versão
                QRYCAB_J->ZCA_MESANO,;                  // Mês/Ano Emis
                StoD(QRYCAB_J->ZCA_DTEMIS),;            // Data Emissao 
                QRYCAB_J->ZCA_HREMIS,;                  // Hora Emissao
                QRYCAB_J->ZCA_USUARI})                  // Usuario Fech

            _lTemDados := .T. 
            QRYCAB_J->(DbSkip())         
        EndDo

        If _lTemDados
            AAdd(_aCabec,{"10-Total 1º Mês Seg. Sint",_aCab1})
            AAdd(_aCabec,{"10-Total 1º Mês Seg. Anal",_aCab2})
            AAdd(_aItem,_aItem1J)
        Endif 

        If ! _lTemDados 
            TRBCAB_J->(DbAppend())
        EndIf 

        Do While ! QRYDET_J->(Eof())
            IncProc("Lendo dados Analítico - 10-Totalizador–1o Mes Seguinte")
            TRBDET_J->(DbAppend())
            TRBDET_J->ZCB_VISAO  := QRYDET_J->ZCB_VISAO	       //	Item Visao
            TRBDET_J->ZCB_FILVIS := QRYDET_J->ZCB_FILVIS       //	Filial Visao
            TRBDET_J->ZCB_VERSAO := QRYDET_J->ZCB_VERSAO       //	Versão
            TRBDET_J->ZCB_MESANO := QRYDET_J->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_J->ZCB_DTEMIS := StoD(QRYDET_J->ZCB_DTEMIS) //	Data Emissao
            TRBDET_J->ZCB_HREMIS := QRYDET_J->ZCB_HREMIS       //	Hora Emissao
            TRBDET_J->ZCB_USUARI := QRYDET_J->ZCB_USUARI       //	Usuario Fech
            TRBDET_J->ZCB_NUMTIT := QRYDET_J->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_J->ZCB_PREFIX := QRYDET_J->ZCB_PREFIX       //	Prefixo     
            TRBDET_J->ZCB_PARCEL := QRYDET_J->ZCB_PARCEL       //	Parcerla
            TRBDET_J->ZCB_TIPO   := QRYDET_J->ZCB_TIPO         //	Tipo
            TRBDET_J->ZCB_CLIENT := QRYDET_J->ZCB_CLIENT       //	Cliente 
            TRBDET_J->ZCB_LOJA   := QRYDET_J->ZCB_LOJA         //	Loja
            TRBDET_J->ZCB_NOMCLI := QRYDET_J->ZCB_NOMCLI       //	Nome
            TRBDET_J->ZCB_VALOR  := QRYDET_J->ZCB_VALOR        //	Valor
            TRBDET_J->ZCB_EMISSA := StoD(QRYDET_J->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2J, { QRYDET_J->ZCB_VISAO, ;        // Item Visao
                QRYDET_J->ZCB_FILVIS, ;       // Filial Visao
                QRYDET_J->ZCB_VERSAO, ;       // Versão
                QRYDET_J->ZCB_MESANO, ;       // Mês/Ano Emis
                StoD(QRYDET_J->ZCB_DTEMIS), ; // Data Emissao 
                QRYDET_J->ZCB_HREMIS, ;       // Hora Emissao
                QRYDET_J->ZCB_USUARI, ;       // Usuario Fech
                QRYDET_J->ZCB_NUMTIT, ;       // No. Titulo
                QRYDET_J->ZCB_PREFIX, ;       // Prefixo
                QRYDET_J->ZCB_PARCEL, ;       // Parcela
                QRYDET_J->ZCB_TIPO, ;         // Tipo
                QRYDET_J->ZCB_CLIENT, ;       // Cliente
                QRYDET_J->ZCB_LOJA, ;         // Loja
                QRYDET_J->ZCB_NOMCLI, ;       // Nome
                QRYDET_J->ZCB_VALOR, ;        // Valor
                StoD(QRYDET_J->ZCB_EMISSA)})    // Emissão 

            _lTemDados := .T. 
            QRYDET_J->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2J)
        Endif 

        If ! _lTemDados 
            TRBDET_J->(DbAppend())
        EndIf
    EndIf     

    //============================================
    // 11-Totalizador–2o Mes Seguinte = K 
    //============================================
    If _cAbas == "00" .Or. _cAbas == "11"
        IncProc("Gerando dados: 11-Totalizador–2o Mes Seguinte ")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '11' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '11' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS, ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_K")
        DBSelectArea("QRYCAB_K")
        
        Count To _nTotRCab
        QRYCAB_K->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_K")
        DBSelectArea("QRYDET_K")
        
        Count To _nTotRDet
        QRYDET_K->(DbGotop())

        _lTemDados := .F.

        Do While ! QRYCAB_K->(Eof())
            IncProc("Lendo dados Sintético - 11-Totalizador–2o Mes Seguinte")
            TRBCAB_K->(DbAppend())
            TRBCAB_K->ZCA_VISAO  := QRYCAB_K->ZCA_VISAO	        // Item Visao
            TRBCAB_K->ZCA_DESVIS := QRYCAB_K->ZCA_DESVIS        // Descr.Visao
            TRBCAB_K->ZCA_FILVIS := QRYCAB_K->ZCA_FILVIS        // Filial Visao
            TRBCAB_K->ZCA_VALOR  := QRYCAB_K->ZCA_VALOR	        // Valor Filial
            TRBCAB_K->ZCA_VERSAO := QRYCAB_K->ZCA_VERSAO        // Versão
            TRBCAB_K->ZCA_MESANO := QRYCAB_K->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_K->ZCA_DTEMIS := StoD(QRYCAB_K->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_K->ZCA_HREMIS := QRYCAB_K->ZCA_HREMIS        // Hora Emissao
            TRBCAB_K->ZCA_USUARI := QRYCAB_K->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1K, { QRYCAB_K->ZCA_VISAO, ;      // Item Visao
                QRYCAB_K->ZCA_DESVIS, ;                 // Descr. Visao
                QRYCAB_K->ZCA_FILVIS, ;                 // Filial Visao
                QRYCAB_K->ZCA_VALOR, ;                  // Valor Filial
                QRYCAB_K->ZCA_VERSAO, ;                 // Versão
                QRYCAB_K->ZCA_MESANO, ;                 // Mês/Ano Emis
                StoD(QRYCAB_K->ZCA_DTEMIS), ;           // Data Emissao 
                QRYCAB_K->ZCA_HREMIS, ;                 // Hora Emissao
                QRYCAB_K->ZCA_USUARI  })                // Usuario Fech
    
            _lTemDados := .T. 
            QRYCAB_K->(DbSkip())         
        EndDo 

        If _lTemDados
            AAdd(_aCabec,{"11-Total 2º Mês Seg Sint",_aCab1})
            AAdd(_aCabec,{"11-Total 2º Mês Seg Anal",_aCab2})
            AAdd(_aItem,_aItem1K)
        Endif 

        If ! _lTemDados
            TRBCAB_K->(DbAppend())
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_K->(Eof())
            IncProc("Lendo dados Analítico - 11-Totalizador–2o Mes Seguinte")
            TRBDET_K->(DbAppend())
            TRBDET_K->ZCB_VISAO  := QRYDET_K->ZCB_VISAO	       //	Item Visao
            TRBDET_K->ZCB_FILVIS := QRYDET_K->ZCB_FILVIS       //	Filial Visao
            TRBDET_K->ZCB_VERSAO := QRYDET_K->ZCB_VERSAO       //	Versão
            TRBDET_K->ZCB_MESANO := QRYDET_K->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_K->ZCB_DTEMIS := StoD(QRYDET_K->ZCB_DTEMIS) //	Data Emissao
            TRBDET_K->ZCB_HREMIS := QRYDET_K->ZCB_HREMIS       //	Hora Emissao
            TRBDET_K->ZCB_USUARI := QRYDET_K->ZCB_USUARI       //	Usuario Fech
            TRBDET_K->ZCB_NUMTIT := QRYDET_K->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_K->ZCB_PREFIX := QRYDET_K->ZCB_PREFIX       //	Prefixo     
            TRBDET_K->ZCB_PARCEL := QRYDET_K->ZCB_PARCEL       //	Parcerla
            TRBDET_K->ZCB_TIPO   := QRYDET_K->ZCB_TIPO         //	Tipo
            TRBDET_K->ZCB_CLIENT := QRYDET_K->ZCB_CLIENT       //	Cliente 
            TRBDET_K->ZCB_LOJA   := QRYDET_K->ZCB_LOJA         //	Loja
            TRBDET_K->ZCB_NOMCLI := QRYDET_K->ZCB_NOMCLI       //	Nome
            TRBDET_K->ZCB_VALOR  := QRYDET_K->ZCB_VALOR        //	Valor
            TRBDET_K->ZCB_EMISSA := StoD(QRYDET_K->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2K, { QRYDET_K->ZCB_VISAO, ;        // Item Visao
                QRYDET_K->ZCB_FILVIS, ;       // Filial Visao
                QRYDET_K->ZCB_VERSAO, ;       // Versão
                QRYDET_K->ZCB_MESANO, ;       // Mês/Ano Emis
                StoD(QRYDET_K->ZCB_DTEMIS), ; // Data Emissao 
                QRYDET_K->ZCB_HREMIS, ;       // Hora Emissao
                QRYDET_K->ZCB_USUARI, ;       // Usuario Fech
                QRYDET_K->ZCB_NUMTIT, ;       // No. Titulo
                QRYDET_K->ZCB_PREFIX, ;       // Prefixo
                QRYDET_K->ZCB_PARCEL, ;       // Parcela
                QRYDET_K->ZCB_TIPO, ;         // Tipo
                QRYDET_K->ZCB_CLIENT, ;       // Cliente
                QRYDET_K->ZCB_LOJA, ;         // Loja
                QRYDET_K->ZCB_NOMCLI, ;       // Nome
                QRYDET_K->ZCB_VALOR, ;        // Valor
                StoD(QRYDET_K->ZCB_EMISSA)})    // Emissão 

            _lTemDados := .T. 
            QRYDET_K->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2K)
        Endif 

        If ! _lTemDados 
            TRBDET_K->(DbAppend())
        EndIf 
    EndIf

    //============================================
    // 12-Totalizador–3o Mes Seguinte = L
    //============================================
    If _cAbas == "00" .Or. _cAbas == "12"
        IncProc("Gerando dados: 12-Totalizador–3o Mes Seguinte ")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '12' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '12' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS, ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_L")
        DBSelectArea("QRYCAB_L")
        
        Count To _nTotRCab
        QRYCAB_L->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_L")
        DBSelectArea("QRYDET_L")
        
        Count To _nTotRDet
        QRYDET_L->(DbGotop())

        _lTemDados := .F.

        Do While ! QRYCAB_L->(Eof())
            IncProc("Lendo dados Sintético - 12-Totalizador–3o Mes Seguinte")
            TRBCAB_L->(DbAppend())
            TRBCAB_L->ZCA_VISAO  := QRYCAB_L->ZCA_VISAO	        // Item Visao
            TRBCAB_L->ZCA_DESVIS := QRYCAB_L->ZCA_DESVIS        // Descr.Visao
            TRBCAB_L->ZCA_FILVIS := QRYCAB_L->ZCA_FILVIS        // Filial Visao
            TRBCAB_L->ZCA_VALOR  := QRYCAB_L->ZCA_VALOR	        // Valor Filial
            TRBCAB_L->ZCA_VERSAO := QRYCAB_L->ZCA_VERSAO        // Versão
            TRBCAB_L->ZCA_MESANO := QRYCAB_L->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_L->ZCA_DTEMIS := StoD(QRYCAB_L->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_L->ZCA_HREMIS := QRYCAB_L->ZCA_HREMIS        // Hora Emissao
            TRBCAB_L->ZCA_USUARI := QRYCAB_L->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1L, { QRYCAB_L->ZCA_VISAO, ;        // Item Visao
                QRYCAB_L->ZCA_DESVIS, ;       // Descr. Visao
                QRYCAB_L->ZCA_FILVIS, ;       // Filial Visao
                QRYCAB_L->ZCA_VALOR, ;        // Valor Filial
                QRYCAB_L->ZCA_VERSAO, ;       // Versão
                QRYCAB_L->ZCA_MESANO, ;       // Mês/Ano Emis
                StoD(QRYCAB_L->ZCA_DTEMIS), ; // Data Emissao 
                QRYCAB_L->ZCA_HREMIS, ;       // Hora Emissao
                QRYCAB_L->ZCA_USUARI})        // Usuario Fech

            _lTemDados := .T. 
            QRYCAB_L->(DbSkip())         
        EndDo

        If _lTemDados
            AAdd(_aCabec,{"12-Total 3º Mês Seg Sint",_aCab1})
            AAdd(_aCabec,{"12-Total 3º Mês Seg Anal",_aCab2})
            AAdd(_aItem,_aItem1L)
        Endif  

        If ! _lTemDados 
            TRBCAB_L->(DbAppend())
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_L->(Eof())
            IncProc("Lendo dados Analítico - 12-Totalizador–3o Mes Seguinte")
            TRBDET_L->(DbAppend())
            TRBDET_L->ZCB_VISAO  := QRYDET_L->ZCB_VISAO	       //	Item Visao
            TRBDET_L->ZCB_FILVIS := QRYDET_L->ZCB_FILVIS       //	Filial Visao
            TRBDET_L->ZCB_VERSAO := QRYDET_L->ZCB_VERSAO       //	Versão
            TRBDET_L->ZCB_MESANO := QRYDET_L->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_L->ZCB_DTEMIS := StoD(QRYDET_L->ZCB_DTEMIS) //	Data Emissao
            TRBDET_L->ZCB_HREMIS := QRYDET_L->ZCB_HREMIS       //	Hora Emissao
            TRBDET_L->ZCB_USUARI := QRYDET_L->ZCB_USUARI       //	Usuario Fech
            TRBDET_L->ZCB_NUMTIT := QRYDET_L->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_L->ZCB_PREFIX := QRYDET_L->ZCB_PREFIX       //	Prefixo     
            TRBDET_L->ZCB_PARCEL := QRYDET_L->ZCB_PARCEL       //	Parcerla
            TRBDET_L->ZCB_TIPO   := QRYDET_L->ZCB_TIPO         //	Tipo
            TRBDET_L->ZCB_CLIENT := QRYDET_L->ZCB_CLIENT       //	Cliente 
            TRBDET_L->ZCB_LOJA   := QRYDET_L->ZCB_LOJA         //	Loja
            TRBDET_L->ZCB_NOMCLI := QRYDET_L->ZCB_NOMCLI       //	Nome
            TRBDET_L->ZCB_VALOR  := QRYDET_L->ZCB_VALOR        //	Valor
            TRBDET_L->ZCB_EMISSA := StoD(QRYDET_L->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2L, {QRYDET_L->ZCB_VISAO, ;        // Item Visao
                QRYDET_L->ZCB_FILVIS, ;       // Filial Visao
                QRYDET_L->ZCB_VERSAO, ;       // Versão
                QRYDET_L->ZCB_MESANO, ;       // Mês/Ano Emis
                StoD(QRYDET_L->ZCB_DTEMIS), ; // Data Emissao 
                QRYDET_L->ZCB_HREMIS, ;       // Hora Emissao
                QRYDET_L->ZCB_USUARI, ;       // Usuario Fech
                QRYDET_L->ZCB_NUMTIT, ;       // No. Titulo
                QRYDET_L->ZCB_PREFIX, ;       // Prefixo
                QRYDET_L->ZCB_PARCEL, ;       // Parcela
                QRYDET_L->ZCB_TIPO, ;         // Tipo
                QRYDET_L->ZCB_CLIENT, ;       // Cliente
                QRYDET_L->ZCB_LOJA, ;         // Loja
                QRYDET_L->ZCB_NOMCLI, ;       // Nome
                QRYDET_L->ZCB_VALOR, ;        // Valor
                StoD(QRYDET_L->ZCB_EMISSA)})   // Emissão 

            _lTemDados := .T. 
            QRYDET_L->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2L)
        Endif 

        If ! _lTemDados 
            TRBDET_L->(DbAppend())
        EndIf 
    EndIf

    //============================================
    // 13-Totalizador–4o Mes Seguinte = M
    //============================================
    If _cAbas == "00" .Or. _cAbas == "13"
        IncProc("Gerando dados: 13-Totalizador–4o Mes Seguinte ")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '13' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '13' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS , ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_M")
        DBSelectArea("QRYCAB_M")
        
        Count To _nTotRCab
        QRYCAB_M->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_M")
        DBSelectArea("QRYDET_M")
        
        Count To _nTotRDet
        QRYDET_M->(DbGotop())

        _lTemDados := .F.

        Do While ! QRYCAB_M->(Eof())
            IncProc("Lendo dados Sintético - 13-Totalizador–4o Mes Seguinte")
            TRBCAB_M->(DbAppend())
            TRBCAB_M->ZCA_VISAO  := QRYCAB_M->ZCA_VISAO	        // Item Visao
            TRBCAB_M->ZCA_DESVIS := QRYCAB_M->ZCA_DESVIS        // Descr.Visao
            TRBCAB_M->ZCA_FILVIS := QRYCAB_M->ZCA_FILVIS        // Filial Visao
            TRBCAB_M->ZCA_VALOR  := QRYCAB_M->ZCA_VALOR	        // Valor Filial
            TRBCAB_M->ZCA_VERSAO := QRYCAB_M->ZCA_VERSAO        // Versão
            TRBCAB_M->ZCA_MESANO := QRYCAB_M->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_M->ZCA_DTEMIS := StoD(QRYCAB_M->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_M->ZCA_HREMIS := QRYCAB_M->ZCA_HREMIS        // Hora Emissao
            TRBCAB_M->ZCA_USUARI := QRYCAB_M->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1M, { QRYCAB_M->ZCA_VISAO, ;       // Item Visao
                            QRYCAB_M->ZCA_DESVIS, ;     // Descr.Visao
                            QRYCAB_M->ZCA_FILVIS, ;     // Filial Visao
                            QRYCAB_M->ZCA_VALOR, ;      // Valor Filial
                            QRYCAB_M->ZCA_VERSAO, ;     // Versão
                            QRYCAB_M->ZCA_MESANO, ;     // Mês/Ano Emis
                            StoD(QRYCAB_M->ZCA_DTEMIS),;// Data Emissao 
                            QRYCAB_M->ZCA_HREMIS, ;     // Hora Emissao
                            QRYCAB_M->ZCA_USUARI } )   // Usuario Fech

            _lTemDados := .T. 
            QRYCAB_M->(DbSkip())         
        EndDo

        If _lTemDados
            AAdd(_aCabec,{"13-Total 4º Mês Seg Sint",_aCab1})
            AAdd(_aCabec,{"13-Total 4º Mês Seg Anal",_aCab2})
            AAdd(_aItem,_aItem1M)
        Endif  
        
        If ! _lTemDados
            TRBCAB_M->(DbAppend())
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_M->(Eof())
            IncProc("Lendo dados Analítico - 13-Totalizador–4o Mes Seguinte")
            TRBDET_M->(DbAppend())
            TRBDET_M->ZCB_VISAO  := QRYDET_M->ZCB_VISAO	       //	Item Visao
            TRBDET_M->ZCB_FILVIS := QRYDET_M->ZCB_FILVIS       //	Filial Visao
            TRBDET_M->ZCB_VERSAO := QRYDET_M->ZCB_VERSAO       //	Versão
            TRBDET_M->ZCB_MESANO := QRYDET_M->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_M->ZCB_DTEMIS := StoD(QRYDET_M->ZCB_DTEMIS) //	Data Emissao
            TRBDET_M->ZCB_HREMIS := QRYDET_M->ZCB_HREMIS       //	Hora Emissao
            TRBDET_M->ZCB_USUARI := QRYDET_M->ZCB_USUARI       //	Usuario Fech
            TRBDET_M->ZCB_NUMTIT := QRYDET_M->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_M->ZCB_PREFIX := QRYDET_M->ZCB_PREFIX       //	Prefixo     
            TRBDET_M->ZCB_PARCEL := QRYDET_M->ZCB_PARCEL       //	Parcerla
            TRBDET_M->ZCB_TIPO   := QRYDET_M->ZCB_TIPO         //	Tipo
            TRBDET_M->ZCB_CLIENT := QRYDET_M->ZCB_CLIENT       //	Cliente 
            TRBDET_M->ZCB_LOJA   := QRYDET_M->ZCB_LOJA         //	Loja
            TRBDET_M->ZCB_NOMCLI := QRYDET_M->ZCB_NOMCLI       //	Nome
            TRBDET_M->ZCB_VALOR  := QRYDET_M->ZCB_VALOR        //	Valor
            TRBDET_M->ZCB_EMISSA := StoD(QRYDET_M->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2M, { QRYDET_M->ZCB_VISAO,;       // Item Visao
                 QRYDET_M->ZCB_FILVIS,;      // Filial Visao
                 QRYDET_M->ZCB_VERSAO,;      // Versão
                 QRYDET_M->ZCB_MESANO,;      // Mês/Ano Emis
                 StoD(QRYDET_M->ZCB_DTEMIS),;// Data Emissao 
                 QRYDET_M->ZCB_HREMIS,;      // Hora Emissao
                 QRYDET_M->ZCB_USUARI,;      // Usuario Fech
                 QRYDET_M->ZCB_NUMTIT,;      // No. Titulo
                 QRYDET_M->ZCB_PREFIX,;      // Prefixo
                 QRYDET_M->ZCB_PARCEL,;      // Parcela
                 QRYDET_M->ZCB_TIPO,;        // Tipo
                 QRYDET_M->ZCB_CLIENT,;      // Cliente
                 QRYDET_M->ZCB_LOJA,;        // Loja
                 QRYDET_M->ZCB_NOMCLI,;      // Nome
                 QRYDET_M->ZCB_VALOR,;       // Valor
                 StoD(QRYDET_M->ZCB_EMISSA) } ) // Emissão 

            _lTemDados := .T. 
            QRYDET_M->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2M)
        Endif 

        If ! _lTemDados 
            TRBDET_M->(DbAppend())
        EndIf 
    EndIf

    //============================================
    // 14-Totalizador–Superior ao 4o Mes" = N 
    //============================================
    If _cAbas == "00" .Or. _cAbas == "14"
        IncProc("Gerando dados: 14-Totalizador–Superior ao 4o Mes ")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '14' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '14' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS , ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_N")
        DBSelectArea("QRYCAB_N")
        
        Count To _nTotRCab
        QRYCAB_N->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_N")
        DBSelectArea("QRYDET_N")
        
        Count To _nTotRDet
        QRYDET_N->(DbGotop())

        _lTemDados := .F.

        Do While ! QRYCAB_N->(Eof())
            IncProc("Lendo dados Sintético - 14-Totalizador–Superior ao 4o Mes")
            TRBCAB_N->(DbAppend())
            TRBCAB_N->ZCA_VISAO  := QRYCAB_N->ZCA_VISAO	        // Item Visao
            TRBCAB_N->ZCA_DESVIS := QRYCAB_N->ZCA_DESVIS        // Descr.Visao
            TRBCAB_N->ZCA_FILVIS := QRYCAB_N->ZCA_FILVIS        // Filial Visao
            TRBCAB_N->ZCA_VALOR  := QRYCAB_N->ZCA_VALOR	        // Valor Filial
            TRBCAB_N->ZCA_VERSAO := QRYCAB_N->ZCA_VERSAO        // Versão
            TRBCAB_N->ZCA_MESANO := QRYCAB_N->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_N->ZCA_DTEMIS := StoD(QRYCAB_N->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_N->ZCA_HREMIS := QRYCAB_N->ZCA_HREMIS        // Hora Emissao
            TRBCAB_N->ZCA_USUARI := QRYCAB_N->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1N, { QRYCAB_N->ZCA_VISAO,;        // Item Visao
                 QRYCAB_N->ZCA_DESVIS,;      // Descr.Visao
                 QRYCAB_N->ZCA_FILVIS,;      // Filial Visao
                 QRYCAB_N->ZCA_VALOR,;       // Valor Filial
                 QRYCAB_N->ZCA_VERSAO,;      // Versão
                 QRYCAB_N->ZCA_MESANO,;      // Mês/Ano Emis
                 StoD(QRYCAB_N->ZCA_DTEMIS),;// Data Emissao 
                 QRYCAB_N->ZCA_HREMIS,;      // Hora Emissao
                 QRYCAB_N->ZCA_USUARI } )   // Usuario Fech

            _lTemDados := .T. 
            QRYCAB_N->(DbSkip())         
        EndDo

        If _lTemDados
            AAdd(_aCabec,{"14-Total Sup. 4º Mês Sint",_aCab1})
            AAdd(_aCabec,{"14-Total Sup. 4º Mês Anal",_aCab2})
            AAdd(_aItem,_aItem1N)
        Endif 

        If ! _lTemDados 
            TRBCAB_N->(DbAppend()) 
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_N->(Eof())
            IncProc("Lendo dados Analítico - 14-Totalizador–Superior ao 4o Mes")
            TRBDET_N->(DbAppend())
            TRBDET_N->ZCB_VISAO  := QRYDET_N->ZCB_VISAO	       //	Item Visao
            TRBDET_N->ZCB_FILVIS := QRYDET_N->ZCB_FILVIS       //	Filial Visao
            TRBDET_N->ZCB_VERSAO := QRYDET_N->ZCB_VERSAO       //	Versão
            TRBDET_N->ZCB_MESANO := QRYDET_N->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_N->ZCB_DTEMIS := StoD(QRYDET_N->ZCB_DTEMIS) //	Data Emissao
            TRBDET_N->ZCB_HREMIS := QRYDET_N->ZCB_HREMIS       //	Hora Emissao
            TRBDET_N->ZCB_USUARI := QRYDET_N->ZCB_USUARI       //	Usuario Fech
            TRBDET_N->ZCB_NUMTIT := QRYDET_N->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_N->ZCB_PREFIX := QRYDET_N->ZCB_PREFIX       //	Prefixo     
            TRBDET_N->ZCB_PARCEL := QRYDET_N->ZCB_PARCEL       //	Parcerla
            TRBDET_N->ZCB_TIPO   := QRYDET_N->ZCB_TIPO         //	Tipo
            TRBDET_N->ZCB_CLIENT := QRYDET_N->ZCB_CLIENT       //	Cliente 
            TRBDET_N->ZCB_LOJA   := QRYDET_N->ZCB_LOJA         //	Loja
            TRBDET_N->ZCB_NOMCLI := QRYDET_N->ZCB_NOMCLI       //	Nome
            TRBDET_N->ZCB_VALOR  := QRYDET_N->ZCB_VALOR        //	Valor
            TRBDET_N->ZCB_EMISSA := StoD(QRYDET_N->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2N, { QRYDET_N->ZCB_VISAO,;       // Item Visao
                 QRYDET_N->ZCB_FILVIS,;      // Filial Visao
                 QRYDET_N->ZCB_VERSAO,;      // Versão
                 QRYDET_N->ZCB_MESANO,;      // Mês/Ano Emis
                 StoD(QRYDET_N->ZCB_DTEMIS),;// Data Emissao 
                 QRYDET_N->ZCB_HREMIS,;      // Hora Emissao
                 QRYDET_N->ZCB_USUARI,;      // Usuario Fech
                 QRYDET_N->ZCB_NUMTIT,;      // No. Titulo
                 QRYDET_N->ZCB_PREFIX,;      // Prefixo
                 QRYDET_N->ZCB_PARCEL, ;     // Parcela
                 QRYDET_N->ZCB_TIPO,;        // Tipo
                 QRYDET_N->ZCB_CLIENT,;      // Cliente
                 QRYDET_N->ZCB_LOJA,;        // Loja
                 QRYDET_N->ZCB_NOMCLI,;      // Nome
                 QRYDET_N->ZCB_VALOR, ;      // Valor
                 dEmissao2N } )             // Emissão 

            _lTemDados := .T. 
            QRYDET_N->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2N)
        Endif

        If ! _lTemDados 
            TRBDET_N->(DbAppend())
        EndIf 
    EndIf

    //=====================================================
    // 15-Totalizador–Emitidas e Vencidas no Mesmo Mes = O
    //=====================================================
    If _cAbas == "00" .Or. _cAbas == "15"
        IncProc("Gerando dados: 15-Totalizador–Emitidas e Vencidas no Mesmo Mes")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '15' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '15' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS , ZCB_NUMTIT" 

        MPSysOpenQuery( _cQry , "QRYCAB_O")
        DBSelectArea("QRYCAB_O")
        
        Count To _nTotRCab
        QRYCAB_O->(DbGotop())
        
        MPSysOpenQuery( _cQry2 , "QRYDET_O")
        DBSelectArea("QRYDET_O")
        
        Count To _nTotRDet
        QRYDET_O->(DbGotop())

        _lTemDados := .F.

        Do While ! QRYCAB_O->(Eof())
            IncProc("Lendo dados Sintético - 15-Totalizador–Emitidas e Vencidas no Mesmo Mes")
            TRBCAB_O->(DbAppend())
            TRBCAB_O->ZCA_VISAO  := QRYCAB_O->ZCA_VISAO	        // Item Visao
            TRBCAB_O->ZCA_DESVIS := QRYCAB_O->ZCA_DESVIS        // Descr.Visao
            TRBCAB_O->ZCA_FILVIS := QRYCAB_O->ZCA_FILVIS        // Filial Visao
            TRBCAB_O->ZCA_VALOR  := QRYCAB_O->ZCA_VALOR	        // Valor Filial
            TRBCAB_O->ZCA_VERSAO := QRYCAB_O->ZCA_VERSAO        // Versão
            TRBCAB_O->ZCA_MESANO := QRYCAB_O->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_O->ZCA_DTEMIS := StoD(QRYCAB_O->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_O->ZCA_HREMIS := QRYCAB_O->ZCA_HREMIS        // Hora Emissao
            TRBCAB_O->ZCA_USUARI := QRYCAB_O->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1O, { QRYCAB_O->ZCA_VISAO,;        // Item Visao
                 QRYCAB_O->ZCA_DESVIS,;      // Descr.Visao
                 QRYCAB_O->ZCA_FILVIS,;      // Filial Visao
                 QRYCAB_O->ZCA_VALOR,;       // Valor Filial
                 QRYCAB_O->ZCA_VERSAO,;      // Versão
                 QRYCAB_O->ZCA_MESANO,;      // Mês/Ano Emis
                 StoD(QRYCAB_O->ZCA_DTEMIS),;// Data Emissao 
                 QRYCAB_O->ZCA_HREMIS,;      // Hora Emissao
                 QRYCAB_O->ZCA_USUARI } )   // Usuario Fech

            _lTemDados := .T. 
            QRYCAB_O->(DbSkip())         
        EndDo

        If _lTemDados
            AAdd(_aCabec,{"15-Emit./Venc. Mesmo Mês Sint",_aCab1})
            AAdd(_aCabec,{"15-Emit./Venc. Mesmo Mês Anal",_aCab2})
            AAdd(_aItem,_aItem1O)
        Endif  

        If ! _lTemDados 
            TRBCAB_O->(DbAppend())
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_O->(Eof())
            IncProc("Lendo dados Analítico - 15-Totalizador–Emitidas e Vencidas no Mesmo Mes")
            TRBDET_O->(DbAppend())
            TRBDET_O->ZCB_VISAO  := QRYDET_O->ZCB_VISAO	       //	Item Visao
            TRBDET_O->ZCB_FILVIS := QRYDET_O->ZCB_FILVIS       //	Filial Visao
            TRBDET_O->ZCB_VERSAO := QRYDET_O->ZCB_VERSAO       //	Versão
            TRBDET_O->ZCB_MESANO := QRYDET_O->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_O->ZCB_DTEMIS := StoD(QRYDET_O->ZCB_DTEMIS) //	Data Emissao
            TRBDET_O->ZCB_HREMIS := QRYDET_O->ZCB_HREMIS       //	Hora Emissao
            TRBDET_O->ZCB_USUARI := QRYDET_O->ZCB_USUARI       //	Usuario Fech
            TRBDET_O->ZCB_NUMTIT := QRYDET_O->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_O->ZCB_PREFIX := QRYDET_O->ZCB_PREFIX       //	Prefixo     
            TRBDET_O->ZCB_PARCEL := QRYDET_O->ZCB_PARCEL       //	Parcerla
            TRBDET_O->ZCB_TIPO   := QRYDET_O->ZCB_TIPO         //	Tipo
            TRBDET_O->ZCB_CLIENT := QRYDET_O->ZCB_CLIENT       //	Cliente 
            TRBDET_O->ZCB_LOJA   := QRYDET_O->ZCB_LOJA         //	Loja
            TRBDET_O->ZCB_NOMCLI := QRYDET_O->ZCB_NOMCLI       //	Nome
            TRBDET_O->ZCB_VALOR  := QRYDET_O->ZCB_VALOR        //	Valor
            TRBDET_O->ZCB_EMISSA := StoD(QRYDET_O->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2O, { QRYDET_O->ZCB_VISAO,;       // Item Visao
                 QRYDET_O->ZCB_FILVIS,;      // Filial Visao
                 QRYDET_O->ZCB_VERSAO,;      // Versão
                 QRYDET_O->ZCB_MESANO,;      // Mês/Ano Emis
                 StoD(QRYDET_O->ZCB_DTEMIS),;// Data Emissao 
                 QRYDET_O->ZCB_HREMIS,;      // Hora Emissao
                 QRYDET_O->ZCB_USUARI,;      // Usuario Fech
                 QRYDET_O->ZCB_NUMTIT,;      // No. Titulo
                 QRYDET_O->ZCB_PREFIX,;      // Prefixo
                 QRYDET_O->ZCB_PARCEL,;      // Parcela
                 QRYDET_O->ZCB_TIPO,;        // Tipo
                 QRYDET_O->ZCB_CLIENT,;      // Cliente
                 QRYDET_O->ZCB_LOJA,;        // Loja
                 QRYDET_O->ZCB_NOMCLI,;      // Nome
                 QRYDET_O->ZCB_VALOR,;       // Valor
                 StoD(QRYDET_O->ZCB_EMISSA) } ) // Emissão 


            _lTemDados := .T. 
            QRYDET_O->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2O)
        Endif 

        If ! _lTemDados 
            TRBDET_O->(DbAppend())
        EndIf 
    EndIf

    //================================================================================
    // 16-Totalizador–Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes  = P
    //================================================================================
    If _cAbas == "00" .Or. _cAbas == "16"
        IncProc("Gerando dados: 16-Totalizador–Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes ")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '16' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '16' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS , ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_P")
        DBSelectArea("QRYCAB_P")
        
        Count To _nTotRCab
        QRYCAB_P->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_P")
        DBSelectArea("QRYDET_P")
        
        Count To _nTotRDet
        QRYDET_P->(DbGotop())
        
        _lTemDados := .F.

        Do While ! QRYCAB_P->(Eof())
            IncProc("Lendo dados Sintético - 16-Totalizador–Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes ")
            TRBCAB_P->(DbAppend())
            TRBCAB_P->ZCA_VISAO  := QRYCAB_P->ZCA_VISAO	        // Item Visao
            TRBCAB_P->ZCA_DESVIS := QRYCAB_P->ZCA_DESVIS        // Descr.Visao
            TRBCAB_P->ZCA_FILVIS := QRYCAB_P->ZCA_FILVIS        // Filial Visao
            TRBCAB_P->ZCA_VALOR  := QRYCAB_P->ZCA_VALOR	        // Valor Filial
            TRBCAB_P->ZCA_VERSAO := QRYCAB_P->ZCA_VERSAO        // Versão
            TRBCAB_P->ZCA_MESANO := QRYCAB_P->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_P->ZCA_DTEMIS := StoD(QRYCAB_P->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_P->ZCA_HREMIS := QRYCAB_P->ZCA_HREMIS        // Hora Emissao
            TRBCAB_P->ZCA_USUARI := QRYCAB_P->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1P, { QRYCAB_P->ZCA_VISAO,;        // Item Visao
                 QRYCAB_P->ZCA_DESVIS,;      // Descr.Visao
                 QRYCAB_P->ZCA_FILVIS,;      // Filial Visao
                 QRYCAB_P->ZCA_VALOR,;       // Valor Filial
                 QRYCAB_P->ZCA_VERSAO,;      // Versão
                 QRYCAB_P->ZCA_MESANO,;      // Mês/Ano Emis
                 StoD(QRYCAB_P->ZCA_DTEMIS),;// Data Emissao 
                 QRYCAB_P->ZCA_HREMIS,;     // Hora Emissao
                 QRYCAB_P->ZCA_USUARI } )   // Usuario Fech


            _lTemDados := .T. 
            QRYCAB_P->(DbSkip())         
        EndDo

        If _lTemDados
            AAdd(_aCabec,{"16-Venc Mês/Emis. Anter Sint",_aCab1})
            AAdd(_aCabec,{"16-Venc Mês/Emis. Anter Anal",_aCab2})
            AAdd(_aItem,_aItem1P)
        Endif 

        If ! _lTemDados 
            TRBCAB_P->(DbAppend())
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_P->(Eof())
            IncProc("Lendo dados Analítico - 16-Totalizador–Com Vencimento no Mes e Qualquer Emissao Anterior ao Mes ")
            TRBDET_P->(DbAppend())
            TRBDET_P->ZCB_VISAO  := QRYDET_P->ZCB_VISAO	       //	Item Visao
            TRBDET_P->ZCB_FILVIS := QRYDET_P->ZCB_FILVIS       //	Filial Visao
            TRBDET_P->ZCB_VERSAO := QRYDET_P->ZCB_VERSAO       //	Versão
            TRBDET_P->ZCB_MESANO := QRYDET_P->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_P->ZCB_DTEMIS := StoD(QRYDET_P->ZCB_DTEMIS) //	Data Emissao
            TRBDET_P->ZCB_HREMIS := QRYDET_P->ZCB_HREMIS       //	Hora Emissao
            TRBDET_P->ZCB_USUARI := QRYDET_P->ZCB_USUARI       //	Usuario Fech
            TRBDET_P->ZCB_NUMTIT := QRYDET_P->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_P->ZCB_PREFIX := QRYDET_P->ZCB_PREFIX       //	Prefixo     
            TRBDET_P->ZCB_PARCEL := QRYDET_P->ZCB_PARCEL       //	Parcerla
            TRBDET_P->ZCB_TIPO   := QRYDET_P->ZCB_TIPO         //	Tipo
            TRBDET_P->ZCB_CLIENT := QRYDET_P->ZCB_CLIENT       //	Cliente 
            TRBDET_P->ZCB_LOJA   := QRYDET_P->ZCB_LOJA         //	Loja
            TRBDET_P->ZCB_NOMCLI := QRYDET_P->ZCB_NOMCLI       //	Nome
            TRBDET_P->ZCB_VALOR  := QRYDET_P->ZCB_VALOR        //	Valor
            TRBDET_P->ZCB_EMISSA := StoD(QRYDET_P->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2P, { QRYDET_P->ZCB_VISAO,;       // Item Visao
                 QRYDET_P->ZCB_FILVIS,;      // Filial Visao
                 QRYDET_P->ZCB_VERSAO,;      // Versão
                 QRYDET_P->ZCB_MESANO,;      // Mês/Ano Emis
                 StoD(QRYDET_P->ZCB_DTEMIS),;// Data Emissao 
                 QRYDET_P->ZCB_HREMIS,;      // Hora Emissao
                 QRYDET_P->ZCB_USUARI,;      // Usuario Fech
                 QRYDET_P->ZCB_NUMTIT,;      // No. Titulo
                 QRYDET_P->ZCB_PREFIX,;      // Prefixo
                 QRYDET_P->ZCB_PARCEL,;      // Parcela
                 QRYDET_P->ZCB_TIPO,;        // Tipo
                 QRYDET_P->ZCB_CLIENT,;      // Cliente
                 QRYDET_P->ZCB_LOJA,;        // Loja
                 QRYDET_P->ZCB_NOMCLI,;      // Nome
                 QRYDET_P->ZCB_VALOR,;       // Valor
                 StoD(QRYDET_P->ZCB_EMISSA) } ) // Emissão 

            _lTemDados := .T. 
            QRYDET_P->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2P)
        Endif 

        If ! _lTemDados 
            TRBDET_P->(DbAppend()) 
        EndIf 
    EndIf

    //=========================================
    // 17–Vendas do Mes Recebidas no Mes = Q
    //=========================================
    If _cAbas == "00" .Or. _cAbas == "17"
        IncProc("Gerando dados: 17–Vendas do Mes Recebidas no Mes ")   
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '17' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '17' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS, ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_Q")
        DBSelectArea("QRYCAB_Q")
        
        Count To _nTotRCab
        QRYCAB_Q->(DbGotop())
        
        MPSysOpenQuery( _cQry2 , "QRYDET_Q")
        DBSelectArea("QRYDET_Q")
        
        Count To _nTotRDet
        QRYDET_Q->(DbGotop())
        
        _lTemDados := .F.

        Do While ! QRYCAB_Q->(Eof())
            IncProc("Lendo dados Sintético - 17–Vendas do Mes Recebidas no Mes")
            TRBCAB_Q->(DbAppend())
            TRBCAB_Q->ZCA_VISAO  := QRYCAB_Q->ZCA_VISAO         // Item Visao
            TRBCAB_Q->ZCA_DESVIS := QRYCAB_Q->ZCA_DESVIS        // Descr.Visao
            TRBCAB_Q->ZCA_FILVIS := QRYCAB_Q->ZCA_FILVIS        // Filial Visao
            TRBCAB_Q->ZCA_VALOR  := QRYCAB_Q->ZCA_VALOR	        // Valor Filial
            TRBCAB_Q->ZCA_VERSAO := QRYCAB_Q->ZCA_VERSAO        // Versão
            TRBCAB_Q->ZCA_MESANO := QRYCAB_Q->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_Q->ZCA_DTEMIS := StoD(QRYCAB_Q->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_Q->ZCA_HREMIS := QRYCAB_Q->ZCA_HREMIS        // Hora Emissao
            TRBCAB_Q->ZCA_USUARI := QRYCAB_Q->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1Q, { QRYCAB_Q->ZCA_VISAO,;        // Item Visao
                 QRYCAB_Q->ZCA_DESVIS,;      // Descr.Visao
                 QRYCAB_Q->ZCA_FILVIS,;      // Filial Visao
                 QRYCAB_Q->ZCA_VALOR,;       // Valor Filial
                 QRYCAB_Q->ZCA_VERSAO,;      // Versão
                 QRYCAB_Q->ZCA_MESANO,;      // Mês/Ano Emis
                 StoD(QRYCAB_Q->ZCA_DTEMIS),;// Data Emissao 
                 QRYCAB_Q->ZCA_HREMIS,;      // Hora Emissao
                 QRYCAB_Q->ZCA_USUARI } )   // Usuario Fech


            _lTemDados := .T. 
            QRYCAB_Q->(DbSkip())         
        EndDo

        If _lTemDados
            AAdd(_aCabec,{"17-Vendas/Recbto no Mês Sint",_aCab1})
            AAdd(_aCabec,{"17-Vendas/Recbto no Mês Anal",_aCab2})
            AAdd(_aItem,_aItem1Q)
        Endif 

        If ! _lTemDados 
            TRBCAB_Q->(DbAppend())   
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_Q->(Eof())
            IncProc("Lendo dados Analítico - 17–Vendas do Mes Recebidas no Mes")
            TRBDET_Q->(DbAppend())
            TRBDET_Q->ZCB_VISAO  := QRYDET_Q->ZCB_VISAO	       //	Item Visao
            TRBDET_Q->ZCB_FILVIS := QRYDET_Q->ZCB_FILVIS       //	Filial Visao
            TRBDET_Q->ZCB_VERSAO := QRYDET_Q->ZCB_VERSAO       //	Versão
            TRBDET_Q->ZCB_MESANO := QRYDET_Q->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_Q->ZCB_DTEMIS := StoD(QRYDET_Q->ZCB_DTEMIS) //	Data Emissao
            TRBDET_Q->ZCB_HREMIS := QRYDET_Q->ZCB_HREMIS       //	Hora Emissao
            TRBDET_Q->ZCB_USUARI := QRYDET_Q->ZCB_USUARI       //	Usuario Fech
            TRBDET_Q->ZCB_NUMTIT := QRYDET_Q->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_Q->ZCB_PREFIX := QRYDET_Q->ZCB_PREFIX       //	Prefixo     
            TRBDET_Q->ZCB_PARCEL := QRYDET_Q->ZCB_PARCEL       //	Parcerla
            TRBDET_Q->ZCB_TIPO   := QRYDET_Q->ZCB_TIPO         //	Tipo
            TRBDET_Q->ZCB_CLIENT := QRYDET_Q->ZCB_CLIENT       //	Cliente 
            TRBDET_Q->ZCB_LOJA   := QRYDET_Q->ZCB_LOJA         //	Loja
            TRBDET_Q->ZCB_NOMCLI := QRYDET_Q->ZCB_NOMCLI       //	Nome
            TRBDET_Q->ZCB_VALOR  := QRYDET_Q->ZCB_VALOR        //	Valor
            TRBDET_Q->ZCB_EMISSA := StoD(QRYDET_Q->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2Q, { QRYDET_Q->ZCB_VISAO,;       // Item Visao
                 QRYDET_Q->ZCB_FILVIS,;      // Filial Visao
                 QRYDET_Q->ZCB_VERSAO,;      // Versão
                 QRYDET_Q->ZCB_MESANO,;      // Mês/Ano Emis
                 StoD(QRYDET_Q->ZCB_DTEMIS),;// Data Emissao 
                 QRYDET_Q->ZCB_HREMIS, ;     // Hora Emissao
                 QRYDET_Q->ZCB_USUARI,;      // Usuario Fech
                 QRYDET_Q->ZCB_NUMTIT,;      // No. Titulo
                 QRYDET_Q->ZCB_PREFIX,;      // Prefixo
                 QRYDET_Q->ZCB_PARCEL, ;     // Parcela
                 QRYDET_Q->ZCB_TIPO, ;       // Tipo
                 QRYDET_Q->ZCB_CLIENT,;      // Cliente
                 QRYDET_Q->ZCB_LOJA,;        // Loja
                 QRYDET_Q->ZCB_NOMCLI, ;     // Nome
                 QRYDET_Q->ZCB_VALOR,;       // Valor
                 StoD(QRYDET_Q->ZCB_EMISSA) } ) // Emissão 


            _lTemDados := .T. 
            QRYDET_Q->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2Q)
        Endif 

        If ! _lTemDados 
            TRBDET_Q->(DbAppend())
        EndIf 
    EndIf

    //=========================================
    // 18-Devolvidas-RA Compensadas = R
    //=========================================
    If _cAbas == "00" .Or. _cAbas == "18"
        IncProc("Gerando dados: 18-Devolvidas-RA Compensadas ")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '18' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '18' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS, ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_R")
        DBSelectArea("QRYCAB_R")
        
        Count To _nTotRCab
        QRYCAB_R->(DbGotop())
        
        MPSysOpenQuery( _cQry2 , "QRYDET_R")
        DBSelectArea("QRYDET_R")
        
        Count To _nTotRDet
        QRYDET_R->(DbGotop())

        _lTemDados := .F.

        Do While ! QRYCAB_R->(Eof())
            IncProc("Lendo dados Sintético - 18-Devolvidas-RA Compensadas")
            TRBCAB_R->(DbAppend())
            TRBCAB_R->ZCA_VISAO  := QRYCAB_R->ZCA_VISAO	        // Item Visao
            TRBCAB_R->ZCA_DESVIS := QRYCAB_R->ZCA_DESVIS        // Descr.Visao
            TRBCAB_R->ZCA_FILVIS := QRYCAB_R->ZCA_FILVIS        // Filial Visao
            TRBCAB_R->ZCA_VALOR  := QRYCAB_R->ZCA_VALOR	        // Valor Filial
            TRBCAB_R->ZCA_VERSAO := QRYCAB_R->ZCA_VERSAO        // Versão
            TRBCAB_R->ZCA_MESANO := QRYCAB_R->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_R->ZCA_DTEMIS := StoD(QRYCAB_R->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_R->ZCA_HREMIS := QRYCAB_R->ZCA_HREMIS        // Hora Emissao
            TRBCAB_R->ZCA_USUARI := QRYCAB_R->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1R, { QRYCAB_R->ZCA_VISAO,;        // Item Visao
                 QRYCAB_R->ZCA_DESVIS,;     // Descr.Visao
                 QRYCAB_R->ZCA_FILVIS,;      // Filial Visao
                 QRYCAB_R->ZCA_VALOR,;       // Valor Filial
                 QRYCAB_R->ZCA_VERSAO,;      // Versão
                 QRYCAB_R->ZCA_MESANO,;      // Mês/Ano Emis
                 StoD(QRYCAB_R->ZCA_DTEMIS),;// Data Emissao 
                 QRYCAB_R->ZCA_HREMIS,;      // Hora Emissao
                 QRYCAB_R->ZCA_USUARI } )   // Usuario Fech

            _lTemDados := .T. 
            QRYCAB_R->(DbSkip())         
        EndDo

        If _lTemDados
            AAdd(_aCabec,{"18-Dev. RA Compensadas Sint",_aCab1})
            AAdd(_aCabec,{"18-Dev. RA Compensadas Anal",_aCab2})
            AAdd(_aItem,_aItem1R)
        Endif 

        If ! _lTemDados 
            TRBCAB_R->(DbAppend())
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_R->(Eof())
            IncProc("Lendo dados Analítico - 18-Devolvidas-RA Compensadas")
            TRBDET_R->(DbAppend())
            TRBDET_R->ZCB_VISAO  := QRYDET_R->ZCB_VISAO	       //	Item Visao
            TRBDET_R->ZCB_FILVIS := QRYDET_R->ZCB_FILVIS       //	Filial Visao
            TRBDET_R->ZCB_VERSAO := QRYDET_R->ZCB_VERSAO       //	Versão
            TRBDET_R->ZCB_MESANO := QRYDET_R->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_R->ZCB_DTEMIS := StoD(QRYDET_R->ZCB_DTEMIS) //	Data Emissao
            TRBDET_R->ZCB_HREMIS := QRYDET_R->ZCB_HREMIS       //	Hora Emissao
            TRBDET_R->ZCB_USUARI := QRYDET_R->ZCB_USUARI       //	Usuario Fech
            TRBDET_R->ZCB_NUMTIT := QRYDET_R->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_R->ZCB_PREFIX := QRYDET_R->ZCB_PREFIX       //	Prefixo     
            TRBDET_R->ZCB_PARCEL := QRYDET_R->ZCB_PARCEL       //	Parcerla
            TRBDET_R->ZCB_TIPO   := QRYDET_R->ZCB_TIPO         //	Tipo
            TRBDET_R->ZCB_CLIENT := QRYDET_R->ZCB_CLIENT       //	Cliente 
            TRBDET_R->ZCB_LOJA   := QRYDET_R->ZCB_LOJA         //	Loja
            TRBDET_R->ZCB_NOMCLI := QRYDET_R->ZCB_NOMCLI       //	Nome
            TRBDET_R->ZCB_VALOR  := QRYDET_R->ZCB_VALOR        //	Valor
            TRBDET_R->ZCB_EMISSA := StoD(QRYDET_R->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2R, { QRYDET_R->ZCB_VISAO,;        // Item Visao
                 QRYDET_R->ZCB_FILVIS,;       // Filial Visao
                 QRYDET_R->ZCB_VERSAO,;       // Versão
                 QRYDET_R->ZCB_MESANO,;       // Mês/Ano Emis
                 StoD(QRYDET_R->ZCB_DTEMIS),; // Data Emissao 
                 QRYDET_R->ZCB_HREMIS,;       // Hora Emissao
                 QRYDET_R->ZCB_USUARI,;       // Usuario Fech
                 QRYDET_R->ZCB_NUMTIT,;       // No. Titulo
                 QRYDET_R->ZCB_PREFIX,;       // Prefixo
                 QRYDET_R->ZCB_PARCEL,;       // Parcela
                 QRYDET_R->ZCB_TIPO,;         // Tipo
                 QRYDET_R->ZCB_CLIENT,;       // Cliente
                 QRYDET_R->ZCB_LOJA,;         // Loja
                 QRYDET_R->ZCB_NOMCLI,;       // Nome
                 QRYDET_R->ZCB_VALOR,;        // Valor
                 StoD(QRYDET_R->ZCB_EMISSA) } ) // Emissão 

            _lTemDados := .T. 
            QRYDET_R->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2R)
        Endif

        If ! _lTemDados 
            TRBDET_R->(DbAppend())
        EndIf 
    EndIf

    //=============================================================
    // 19-Devolvidas-NCC Compensadas no Mês(Tipos NF com NCC) = S
    //=============================================================
    If _cAbas == "00" .Or. _cAbas == "19"
        IncProc("Gerando dados: 19-Devolvidas-NCC Compensadas no Mês(Tipos NF com NCC) ")
        //-------- Query Sintético
        _cQry := " SELECT ZCA_FILIAL, ZCA_VISAO, ZCA_DESVIS, ZCA_FILVIS, ZCA_VALOR, ZCA_VERSAO, ZCA_MESANO, ZCA_DTEMIS, ZCA_HREMIS, ZCA_USUARI "
        _cQry += " FROM " + RetSqlName("ZCA") + " ZCA "
        _cQry += " WHERE ZCA_MESANO = '" + MV_PAR01 + "' "
        _cQry += " AND ZCA.D_E_L_E_T_ =' ' "
        _cQry += " AND ZCA_VISAO = '19' "
        _cQry += " ORDER BY ZCA_VERSAO, ZCA_FILVIS " 

        //-------- Query Analítico
        _cQry2 := " SELECT ZCB_FILIAL, ZCB_VISAO, ZCB_FILVIS, ZCB_VERSAO, ZCB_MESANO, ZCB_DTEMIS, ZCB_HREMIS, ZCB_USUARI, ZCB_NUMTIT, 
        _cQry2 += " ZCB_PREFIX, ZCB_PARCEL, ZCB_TIPO, ZCB_CLIENT, ZCB_LOJA, ZCB_NOMCLI, ZCB_VALOR, ZCB_EMISSA "
        _cQry2 += " FROM " + RetSqlName("ZCB") + " ZCB "
        _cQry2 += " WHERE ZCB_MESANO = '" + MV_PAR01 + "' "
        _cQry2 += " AND ZCB.D_E_L_E_T_ =' ' "
        _cQry2 += " AND ZCB_VISAO = '19' "
        If !Empty(_cFilter)
            _cQry2 += AFIN040H(_cFilter,"ZCB")
        EndIf
        _cQry2 += " ORDER BY ZCB_VERSAO, ZCB_FILVIS, ZCB_NUMTIT " 

        MPSysOpenQuery( _cQry , "QRYCAB_S")
        DBSelectArea("QRYCAB_S")
        
        Count To _nTotRCab
        QRYCAB_S->(DbGotop())

        MPSysOpenQuery( _cQry2 , "QRYDET_S")
        DBSelectArea("QRYDET_S")
        
        Count To _nTotRDet
        QRYDET_S->(DbGotop())

        _lTemDados := .F.

        Do While ! QRYCAB_S->(Eof())
            IncProc("Lendo dados Sintético - 19-Devolvidas-NCC Compensadas no Mês(Tipos NF com NCC)")
            TRBCAB_S->(DbAppend())
            TRBCAB_S->ZCA_VISAO  := QRYCAB_S->ZCA_VISAO	        // Item Visao
            TRBCAB_S->ZCA_DESVIS := QRYCAB_S->ZCA_DESVIS        // Descr.Visao
            TRBCAB_S->ZCA_FILVIS := QRYCAB_S->ZCA_FILVIS        // Filial Visao
            TRBCAB_S->ZCA_VALOR  := QRYCAB_S->ZCA_VALOR	        // Valor Filial
            TRBCAB_S->ZCA_VERSAO := QRYCAB_S->ZCA_VERSAO        // Versão
            TRBCAB_S->ZCA_MESANO := QRYCAB_S->ZCA_MESANO        // Mês/Ano Emis
            TRBCAB_S->ZCA_DTEMIS := StoD(QRYCAB_S->ZCA_DTEMIS)  // Data Emissao
            TRBCAB_S->ZCA_HREMIS := QRYCAB_S->ZCA_HREMIS        // Hora Emissao
            TRBCAB_S->ZCA_USUARI := QRYCAB_S->ZCA_USUARI        // Usuario Fech

            AAdd(_aItem1S, { QRYCAB_S->ZCA_VISAO,;        // Item Visao
                 QRYCAB_S->ZCA_DESVIS,;      // Descr.Visao
                 QRYCAB_S->ZCA_FILVIS,;      // Filial Visao
                 QRYCAB_S->ZCA_VALOR,;       // Valor Filial
                 QRYCAB_S->ZCA_VERSAO,;      // Versão
                 QRYCAB_S->ZCA_MESANO,;      // Mês/Ano Emis
                 StoD(QRYCAB_S->ZCA_DTEMIS),;// Data Emissao 
                 QRYCAB_S->ZCA_HREMIS,;      // Hora Emissao
                 QRYCAB_S->ZCA_USUARI } )   // Usuario Fech

            _lTemDados := .T. 
            QRYCAB_S->(DbSkip())         
        EndDo

        If _lTemDados
            AAdd(_aCabec,{"19-Dev NCC Compens Mês Sint",_aCab1})
            AAdd(_aCabec,{"19-Dev NCC Compens Mês Anal",_aCab2})
            AAdd(_aItem,_aItem1S)
        Endif

        If ! _lTemDados 
            TRBCAB_S->(DbAppend())
        EndIf 

        _lTemDados := .F.

        Do While ! QRYDET_S->(Eof())
            IncProc("Lendo dados Analítico - 19-Devolvidas-NCC Compensadas no Mês(Tipos NF com NCC)")      
            TRBDET_S->(DbAppend())
            TRBDET_S->ZCB_VISAO  := QRYDET_S->ZCB_VISAO	       //	Item Visao
            TRBDET_S->ZCB_FILVIS := QRYDET_S->ZCB_FILVIS       //	Filial Visao
            TRBDET_S->ZCB_VERSAO := QRYDET_S->ZCB_VERSAO       //	Versão
            TRBDET_S->ZCB_MESANO := QRYDET_S->ZCB_MESANO       //	Mês/Ano Emis
            TRBDET_S->ZCB_DTEMIS := StoD(QRYDET_S->ZCB_DTEMIS) //	Data Emissao
            TRBDET_S->ZCB_HREMIS := QRYDET_S->ZCB_HREMIS       //	Hora Emissao
            TRBDET_S->ZCB_USUARI := QRYDET_S->ZCB_USUARI       //	Usuario Fech
            TRBDET_S->ZCB_NUMTIT := QRYDET_S->ZCB_NUMTIT       //	No. Titulo  
            TRBDET_S->ZCB_PREFIX := QRYDET_S->ZCB_PREFIX       //	Prefixo     
            TRBDET_S->ZCB_PARCEL := QRYDET_S->ZCB_PARCEL       //	Parcerla
            TRBDET_S->ZCB_TIPO   := QRYDET_S->ZCB_TIPO         //	Tipo
            TRBDET_S->ZCB_CLIENT := QRYDET_S->ZCB_CLIENT       //	Cliente 
            TRBDET_S->ZCB_LOJA   := QRYDET_S->ZCB_LOJA         //	Loja
            TRBDET_S->ZCB_NOMCLI := QRYDET_S->ZCB_NOMCLI       //	Nome
            TRBDET_S->ZCB_VALOR  := QRYDET_S->ZCB_VALOR        //	Valor
            TRBDET_S->ZCB_EMISSA := StoD(QRYDET_S->ZCB_EMISSA) //	Emissão

            AAdd(_aItem2S, { QRYDET_S->ZCB_VISAO,;       // Item Visao
                 QRYDET_S->ZCB_FILVIS,;      // Filial Visao
                 QRYDET_S->ZCB_VERSAO,;      // Versão
                 QRYDET_S->ZCB_MESANO,;      // Mês/Ano Emis
                 StoD(QRYDET_S->ZCB_DTEMIS),;// Data Emissao 
                 QRYDET_S->ZCB_HREMIS,;      // Hora Emissao
                 QRYDET_S->ZCB_USUARI,;      // Usuario Fech
                 QRYDET_S->ZCB_NUMTIT,;      // No. Titulo
                 QRYDET_S->ZCB_PREFIX,;      // Prefixo
                 QRYDET_S->ZCB_PARCEL,;      // Parcela
                 QRYDET_S->ZCB_TIPO,;        // Tipo
                 QRYDET_S->ZCB_CLIENT,;      // Cliente
                 QRYDET_S->ZCB_LOJA,;        // Loja
                 QRYDET_S->ZCB_NOMCLI,;      // Nome
                 QRYDET_S->ZCB_VALOR,;      // Valor
                 StoD(QRYDET_S->ZCB_EMISSA) } ) // Emissão 


            _lTemDados := .T. 
            QRYDET_S->(DbSkip())  
        EndDo

        If _lTemDados
            AAdd(_aItem,_aItem2S)
        Endif 

        If ! _lTemDados 
            TRBDET_S->(DbAppend())
        EndIf 
    EndIf

     If _lTdAbas
        _cAbas := "00"
    EndIf

    End Sequence

Return Nil 
/*
===============================================================================================================================
Programa----------: AFIN040E
Autor-------------: Jose Gavetti
Data da Criacao---: 16/10/2025
Descrição---------: Gera arquivo.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN040E(_cTitulo)

    Local _cArq  As Character
    Local _cDir  As Character

    Default _cTitulo  := ""

    _cDir := GetTempPath()                                        // Diretório de Geração das planilhas.  
    _cArq := "_"+DToS(Date())+"_"+StrTran(Time(),":","")+".xlsx"   // Nome da planilha a ser gerada.
    _cArq := "Fechamento Financeiro"+_cArq                        // Nome da planilha a ser gerada.   

    If _cAbas == "00"
        _cTitulo := "Fechamento Financeiro - Período: " + SubStr(MV_PAR01,1,2) + "/" + SubStr(MV_PAR01,3,4)
    Endif

    U_ITGEREXCEL(_cArq,_cDir,_cTitulo,"Relatorio Financeiro",_aCabec,_aItem,,,,,.T.,,,.T.)

Return

/*
===============================================================================================================================
Programa----------: AFIN040F
Autor-------------: Jose Gavetti
Data da Criacao---: 21/10/2025
Descrição---------: Finaliza fechamento.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN040F(_oDlgFin)

    // Limpos os array de impressão.
    _aCabec := {}
    _aItem  := {}

    _oDlgFin:End()

Return

/*
===============================================================================================================================
Programa----------: AFIN040G
Autor-------------: Jose Gavetti
Data da Criacao---: 21/10/2025
Descrição---------: Monta cabeçalho para Excel.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN040G(_aCab1,_aCab2)

    //Adiciona cabeçalho Sintético
    AAdd(_aCab1,{"ITEM"             ,1           ,1         ,.F.})
    AAdd(_aCab1,{"DESCRIÇÃO"        ,1           ,1         ,.F.})    
    AAdd(_aCab1,{"FILIAL "          ,1           ,1         ,.F.})    
    AAdd(_aCab1,{"VALOR"            ,3           ,3         ,.F.})    
    AAdd(_aCab1,{"VERSÃO"           ,1           ,1         ,.F.})    
    AAdd(_aCab1,{"MÊS/ANO EMIS"     ,1           ,1         ,.F.}) 
    AAdd(_aCab1,{"DATA EMISSÃO"     ,1           ,1         ,.F.}) 
    AAdd(_aCab1,{"HORA EMISSÃO"     ,1           ,1         ,.F.})
    AAdd(_aCab1,{"USUÁRIO FECH"     ,1           ,1         ,.F.}) 

    //Adicona Cabeçalho Analitico
    AAdd(_aCab2,{"ITEM"             ,1           ,1         ,.F.})
    AAdd(_aCab2,{"DESCRIÇÃO"        ,1           ,1         ,.F.})           
    AAdd(_aCab2,{"VERSÃO"           ,1           ,1         ,.F.})    
    AAdd(_aCab2,{"MÊS/ANO EMIS"     ,1           ,1         ,.F.}) 
    AAdd(_aCab2,{"DATA EMISSÃO"     ,1           ,1         ,.F.}) 
    AAdd(_aCab2,{"HORA EMISSÃO"     ,1           ,1         ,.F.})
    AAdd(_aCab2,{"USUÁRIO FECH"     ,1           ,1         ,.F.}) 
    AAdd(_aCab2,{"NU. TÍTULO"       ,1           ,1         ,.F.})
    AAdd(_aCab2,{"PREFIXO"          ,1           ,1         ,.F.}) 
    AAdd(_aCab2,{"PARCELA"          ,1           ,1         ,.F.}) 
    AAdd(_aCab2,{"TIPO"             ,1           ,1         ,.F.}) 
    AAdd(_aCab2,{"CLIENTE"          ,1           ,1         ,.F.}) 
    AAdd(_aCab2,{"LOJA"             ,1           ,1         ,.F.}) 
    AAdd(_aCab2,{"NOME"             ,1           ,1         ,.F.}) 
    AAdd(_aCab2,{"VALOR"            ,3           ,3         ,.F.})
    AAdd(_aCab2,{"EMISSÃO"          ,1           ,1         ,.F.}) 

Return

/*
===============================================================================================================================
Programa----------: AFIN040H
Autor-------------: Jose Gavetti
Data da Criacao---: 21/10/2025
Descrição---------: Filtro de Pesquisa
Parametros--------: (_cPesq)Conteudo a ser Pesquisado.
Retorno-----------: Query contendo filtro da pesquisa. 
===============================================================================================================================
*/
Static Function AFIN040H(_cPesq,_cTab)

    Local _cFilter   := ""                         As Character
    Local _cSqlFilt  := ""                         As Character

    Default _cPesq   := ""
    Default _cTab    := ""

    _cFilter := AllTrim(_cPesq) 

    If !Empty(_cFilter)
        _cSqlFilt += " AND ("
        _cSqlFilt += " "+_cTab+"_FILIAL    LIKE '%" + _cFilter + "%' OR"
        If _cTab == "E1"
            _cSqlFilt += " "+_cTab+"_NUM       LIKE '%" + _cFilter + "%' OR"
            _cSqlFilt += " "+_cTab+"_PREFIXO   LIKE '%" + _cFilter + "%' OR"
            _cSqlFilt += " "+_cTab+"_PARCELA   LIKE '%" + _cFilter + "%' OR"
            _cSqlFilt += " "+_cTab+"_CLIENTE   LIKE '%" + _cFilter + "%' OR"
            _cSqlFilt += " "+_cTab+"_EMISSAO   LIKE '%" + _cFilter + "%' OR"
        Else 
            _cSqlFilt += " "+_cTab+"_NUMTIT    LIKE '%" + _cFilter + "%' OR"
            _cSqlFilt += " "+_cTab+"_PREFIX    LIKE '%" + _cFilter + "%' OR"
            _cSqlFilt += " "+_cTab+"_PARCEL    LIKE '%" + _cFilter + "%' OR"
            _cSqlFilt += " "+_cTab+"_CLIENT    LIKE '%" + _cFilter + "%' OR"
            _cSqlFilt += " "+_cTab+"_EMISSA    LIKE '%" + _cFilter + "%' OR"
        Endif   
        _cSqlFilt += " "+_cTab+"_TIPO      LIKE '%" + _cFilter + "%' OR"
        _cSqlFilt += " "+_cTab+"_LOJA      LIKE '%" + _cFilter + "%' OR"
        _cSqlFilt += " "+_cTab+"_NOMCLI    LIKE '%" + _cFilter + "%' OR"
        _cSqlFilt += " "+_cTab+"_VALOR     LIKE '%" + _cFilter + "%'"
        _cSqlFilt += " )"
    EndIf

Return _cSqlFilt

/*
===============================================================================================================================
Programa----------: AFIN040I
Autor-------------: Jose Gavetti
Data da Criacao---: 21/10/2025
Descrição---------: Pesquisa Títulos.
Parametros--------: nPasta
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN040I(_cAba,_cOrdem)

    Local _oGet1      := Nil                       As Object
    Local _oDlg       := Nil                       As Object
    Local _cFilter      := Space(50)                 As Character
    Local _nOpca      := 0                         As Numeric

    Default _cAba      := ""
    Default _cOrdem    := ""

    DEFINE MSDIALOG _oDlg TITLE "Pesquisar" FROM 178,181 TO 259,697 PIXEL 
    @020,003 MsGet _oGet1 Var _cFilter Size 212,009 PIXEL OF _oDlg Picture "@!" F3 "SE1"
    DEFINE SBUTTON FROM 020,227 Type 1 ENABLE ACTION ( _nOpca := 1 , _oDlg:End() ) OF _oDlg
    ACTIVATE MSDIALOG _oDlg CENTERED

    If _nOpca == 1
        If SubStr(MV_PAR02,1,1) == "1"
            AFIN040B(_cOrdem,_cFilter)
        Else
            AFIN040D(_cOrdem,_cFilter)
        Endif    
        // Atualiza os Browses na tela após a pesquisa
        &("oMarkBRW1" + _cAba + ":oBrowse:Refresh()")
        &("oMarkBRW2" + _cAba + ":oBrowse:Refresh()")
    EndIf

Return

/*
===============================================================================================================================
Programa----------: AFIN040J
Autor-------------: Jose Gavetti
Data da Criacao---: 21/10/2025
Descrição---------: Cria as tabelas temporárias.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN040J(cAliasSufix, aStruCab, aStruDet)

    Local cCabAlias   := "TRBCAB_" + cAliasSufix   As Character
    Local cDetAlias   := "TRBDET_" + cAliasSufix   As Character
    Local _oTemp      := Nil                       As Object

    _otemp := FWTemporaryTable():New(cCabAlias, aStruCab)
    _otemp:AddIndex( "01", {"ZCA_FILVIS", "ZCA_VERSAO"} )
    _otemp:Create()

    _otemp := FWTemporaryTable():New(cDetAlias, aStruDet)
    _otemp:AddIndex( "01", {"ZCB_FILVIS","ZCB_NUMTIT","ZCB_PREFIX", "ZCB_VERSAO"} )
    _otemp:Create()

Return

/*
===============================================================================================================================
Programa----------: AFIN040K
Autor-------------: Jose Gavetti
Data da Criacao---: 21/10/2025
Descrição---------: Fecha as áreas de trabalho (tabelas) de Cabeçalho e Detalhe.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN040K()

    Local cSufixAtual := ""                     As Character
    Local cSufixos    := "ABCDEFGHIJKLMNOPQRS"  As Character
    Local cCabAlias   := ""                     As Character
    Local cDetAlias   := ""                     As Character
    Local nI          := 0                      As Numeric

    For nI := 1 To Len(cSufixos)
        cSufixAtual := SubStr(cSufixos, nI, 1)
        cCabAlias := "TRBCAB_" + cSufixAtual
        cDetAlias := "TRBDET_" + cSufixAtual
        &(cCabAlias)->(DbCloseArea())
        &(cDetAlias)->(DbCloseArea())
    Next nI

Return
