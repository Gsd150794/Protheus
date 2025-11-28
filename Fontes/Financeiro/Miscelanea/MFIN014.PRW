/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |03/06/2024| Chamado 47277. Ajuste para execução da rotina somente se E1_SALDO > 0. 
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
Igor Melgaço  |21/01/2025| Chamado 49269. Ajustes para validação data de Vecto.
===============================================================================================================================
*/

#Include	"Protheus.Ch"
#Include	"FWMVCDef.Ch"

#Define		TITULO	"Análise de Pagamentos previstos"

/*
===============================================================================================================================
Programa----------: MFIN014
Autor-------------: Julio de Paula Paz
Data da Criacao---: 22/02/2018
Descrição---------: Rotina de Análise de pagamentos previsos.  Chamado 22721.
Parametros--------: Nenhum
Retorno-----------: Nenhum 
===============================================================================================================================
*/

User Function MFIN014()

Local oproc

//===========================================================================
//| Define formato de data para exibição nas telas da rotina                |
//===========================================================================
SET DATE FORMAT TO "DD/MM/YYYY"

//Grava Log de execução da rotina
//U_ITLOGACS( "MFIN014" )

FWMsgRun( ,{|oproc| MFIN014INI(oproc) } , "Processando..." , "Iniciando o processamento..." )
	
Return

/*
===============================================================================================================================
Programa----------: MFIN014INI
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/03/2014
Descrição---------: Rotina de montagem da tela de processamento
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN014INI(oProc2)
Local oProc
Local _aParAux	    := {}
Local _aParRet	    := {}
Local _aCpos		 := MFIN014CPS()
Local _nreg		    := 0
Local _aDados		 := {}
Local _nI			 := 0
Local _carq		    := ""
Local _lInverte    := .F.
Local _aSizeAut    := MsAdvSize(.T.)
Local _aCamposTela := {}
Local _aButtons    := {}
Local _lRet        := .T.  
Local nI	          := 0

Default oProc2 := Nil

Private oMarkBRW	 := Nil
Private cAliasAux	 := GetNextAlias()
Private _nTotReg	 := 0
Private cDtIni	    := ""
Private _aDadosRej := {}
Private _oMarkTitulo, _cMarca := GetMark() 

Begin Sequence
 
   //aAdd( _aParAux , { 1 , "Selecione arquivo:" , Space(150)	, "@!"		                           , ""	, "DIR"		, "" , 120 , .F. } ) 	//| 01 |
   //aAdd( _aParAux , { 1 , "Selecione arquivo .CSV:",MV_PAR01, "@!"	, "", "DIR","", 100, .T. } )
	aAdd( _aParAux , { 6 , "Selecione arquivo .CSV:", Space(150) ,"","","",100,.T.,"Todos os arquivos (*.CSV) |*.CSV","C:\",GETF_LOCALHARD+GETF_NETWORKDRIVE})
   
   aAdd( _aParAux , { 2 , "Atualização"             , "1"        , {"1-Pela data da planilha","2-Pela condição de pagamento"} , 100 ,".T.",.T.,".T."}) 

   For nI := 1 To Len( _aParAux )
	   aAdd( _aParRet , _aParAux[nI][03] )
   Next nI

   If !ParamBox( _aParAux , "Análise de pagamentos previstos" , @_aParRet )
	  U_ITMsg( "Operação cancelada pelo usuário!" , "Atenção!",,1 )
	  Break // Return
   EndIf

   //=================================================================================
   // Importa a planilha e permite as alterações das datas de vencimentos.
   //=================================================================================

   ProcRegua(0)
   IncProc( "Abrindo arquivo..." )

   //----------------------------------------------------------------------------------------------//
   // Layout da Planilha a ser importada.                                                          //
   //----------------------------------------------------------------------------------------------//
   //CNPJ_FORNECEDOR;CODIGO_CLIENTE;NOME_CLIENTE                       ;NUMERO_DOCUMENTO;PARCELA;VALOR_DOCUMENTO;NOVO_VENCIMENTO  // 92
   //01257995000133 ;000578        ;CARREFOUR COMERCIO E INDUSTRIA LTDA;003998821       ;01     ;6298,66        ;11/02/2018   //
   //01257995000133 ;000578        ;CARREFOUR COMERCIO E INDUSTRIA LTDA;004018531       ;02     ;197701,62      ;20/12/2017 //
   //01257995002187 ;000578        ;CARREFOUR COMERCIO E INDUSTRIA LTDA;001856011       ;       ;102964,05      ;11/12/2017 //
   //----------------------------------------------------------------------------------------------//

   If (Upper(Right(AllTrim(MV_PAR01),4))) == ".CSV" 

      _carq := AllTrim(MV_PAR01)

      If FT_FUSE(_carq) == -1
         U_ITMsg("1-Falha ao abrir o arquivo: "+_carq,;
                 "Erro Abertura de Arquivo",;
	             "Verfifique se o arquivo não está sendo utilizado por outro aplicativo, ou se o arquivo foi salvo corretamente no formato CSV e possui ponto-e-virgula (;) como separador de colunas.",1)
	     _lRet := .F. //Return .F.
	     Break
	
      EndIf 
	          
      FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
      _cDados := FT_FREADLN()
      _cDados := Upper(AllTrim(_cDados))
      _cDados := StrTran(_cDados," ","") 
   
      If !("CNPJ_FORNECEDOR;CODIGO_CLIENTE;NOME_CLIENTE;NUMERO_DOCUMENTO;PARCELA;VALOR_DOCUMENTO;NOVO_VENCIMENTO" $ SubStr(_cDados,1,100))  // 92
	     U_ITMsg("Layout de arquivo inválido, contido no arquivo: "+_carq,;
                 "Layout de Arquivo",;
		         "O layout do arquivo a ser processado, obrigatoriamente precisa seguir o padrão de colunas: "+CRLF+;
		         "CNPJ_FORNECEDOR; CODIGO_CLIENTE; NOME_CLIENTE; NUMERO_DOCUMENTO; PARCELA; VALOR_DOCUMENTO; NOVO_VENCIMENTO;",1)
	     _lRet := .F. // Return .F.
	     Break
      EndIf

      //Fecha arquivo e prepara parâmetro com arquivo convertido
      FT_FUSE()
   Else
      U_ITMsg("O arquivo informado: "+AllTrim(MV_PAR01)+" não tem extenção [ .CSV ] ",;
              "Arquivo inválido",;
	          "Favor informar um arquivo no formato [ .CSV ].",1)
      _lRet := .F. // Return .F.
   EndIf

   ChkFile("SE1")
   ChkFile("SA1")

   If FT_FUSE(MV_PAR01) == -1
      U_ITMsg("1-Falha ao abrir o arquivo: "+_carq,;
              "Erro Abertura de Arquivo",;
	          "Verfifique se o arquivo não está sendo utilizado por outro aplicativo, ou se o arquivo foi salvo corretamente no formato CSV e possui ponto-e-virgula (;) como separador de colunas.",1)
      _lRet := .F. // Return .F.
      Break
   EndIf 

   FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
	
   _nReg:= FT_FLASTREC()

   ProcRegua(_nReg)
	
   FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
	
   If _nReg == 0 //O arquivo informado nao possui nenhuma linha de dados
		
      U_ITMsg("O arquivo informado para relizar a importação não possui dados.",;
	          "Arquivo inválido","Favor verificar se o arquivo informado esta correto.",1)
      _lRet := .F. // Return .F.
      Break
   EndIf


   //=========================================
   // Faz a leitura dos dados
   //=========================================
   _aDados := MFIN014L4(_nreg,oproc2) //Faz leitura dos dados 
	
   If Empty(_aDados) // Len(_aDados) <= 0
      U_ITMsg("Não foram encontrados registros válidos no arquivo!" ,"Atenção!",,1 )
      Break //Return	
   EndIf

   If Len(_aDadosRej) > 0
      U_ITListBox( 'Lista de Títulos da Planilha não Localizados no Protheus' ,;  
                 { "CNPJ da Filial", "Prefixo", "Titulo" , "Parcela" , "Tipo", "Cliente"},;
		           _aDadosRej,.T.,1)
   EndIf

   //=========================================
   //ordena titulos no browse
   //=========================================
   _aDados := aSort( _aDados,,, { |x,y| x[06]+x[03]+x[04]+x[01]+x[02] < y[06]+y[03]+y[04]+y[01]+y[02] } )

   ProcRegua(Len(_aDados))
   
   //================================================================================
   // Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
   //================================================================================
   If Select(cAliasAux) > 0
	   (cAliasAux)->( DBCloseArea() )
   EndIf

   //================================================================================
   // Permite o uso do arquivo criado dentro do protheus.
   //================================================================================
   _otemp := FWTemporaryTable():New( cAliasAux, _aCpos )

   _otemp:AddIndex( "01",{"FILIAL","TITU"} )
   _otemp:AddIndex( "02",{"FILIAL","VENCTO"} )

   _otemp:Create()
   
   _nI := 0

   //==============================================
   // Grava os dados lidos na tabela temporária
   //==============================================

   While _nI < Len(_aDados)
	
	   _nI++
	   IncProc( "Analisando... ["+ StrZero( _nI , 6 ) +"] de ["+ StrZero( _nI , 6 ) +"]" )
	
	   //=========================================================================================
	   //localiza título
	   // se não achar e For parcela 001 procura com parcela em branco
	   // se não achar não mostra na tela
	   //==========================================================================================
	   DBSelectArea("SE1")
	   SE1->(DBSetOrder(2))
	
	   If .not. SE1->(DBSeek(_aDados[_nI][06]+_aDados[_nI][03]+_aDados[_nI][04]+"1  "+_aDados[_nI][01]+_aDados[_nI][02]))
		   If .not. (_aDados[_nI][02] == "001" .Or. _aDados[_nI][02] == "01")
			   _nI++
			   Loop
		   ElseIf .not. 	SE1->(DBSeek(_aDados[_nI][06]+_aDados[_nI][03]+_aDados[_nI][04]+"1  "+_aDados[_nI][01]))
			   _nI++
			   Loop
		   EndIf
	   EndIf
	
	   (cAliasAux)->( RecLock( cAliasAux , .T. ) )

		   (cAliasAux)->FILIAL		:= _aDados[_nI][06]
		   (cAliasAux)->CLIENTE	   := _aDados[_nI][03]
		   (cAliasAux)->LOJA		   := _aDados[_nI][04]
		   (cAliasAux)->NOME 		:= Posicione("SA1",1,xFilial("SA1")+_aDados[_nI][03]+_aDados[_nI][04],"A1_NOME")
		   (cAliasAux)->REDE		   := Capital( AllTrim( Posicione("ACY",1, xFilial("ACY")+Posicione("SA1",1,xFilial("SA1")+_aDados[_nI][03]+_aDados[_nI][04],"A1_GRPVEN"),"ACY_DESCRI")))
		   (cAliasAux)->CGC		   := MFIN014CGC( _aDados[_nI][07] )
		   (cAliasAux)->TITU		   := _aDados[_nI][01]
		   (cAliasAux)->PARCELA	   := _aDados[_nI][02]
		   (cAliasAux)->CONDI		:= Posicione("SA1",1,xFilial("SA1")+_aDados[_nI][03]+_aDados[_nI][04],"A1_COND")
		   (cAliasAux)->DCONDI		:= Posicione("SE4",1,xFilial("SE4")+(cAliasAux)->CONDI,"E4_DESCRI")
		   (cAliasAux)->VALOR		:= SE1->E1_VALOR
		   (cAliasAux)->VENCTO		:= SE1->E1_VENCTO
		   (cAliasAux)->VENCREA	   := SE1->E1_VENCREA
		   (cAliasAux)->VENCNVO	   := _aDados[_nI][05]
		   (cAliasAux)->REGSE1		:= SE1->( Recno() )
		   (cAliasAux)->SITUACAO   := "NÃO PROCESSADO"
         (cAliasAux)->OBSERVACAO := ""
         (cAliasAux)->NOMEFIL    := AllTrim(FWFilialName(cEmpAnt,(cAliasAux)->FILIAL,1))
         (cAliasAux)->HISTORICO  := _aDados[_nI][08]
	   (cAliasAux)->( MSUnLock() )

   EndDo

   _nTotReg := (cAliasAux)->( Recno())

   //==============================================
   // Substituir FWMarkBrowse() por MSSELECT.
   //==============================================
   aAdd( _aCamposTela , {"MARCA"		   ,    , "Marca"		   , "@!" } )
   aAdd( _aCamposTela , {"FILIAL"		, "" , "Filial"		, "@!" } )
   aAdd( _aCamposTela , {"NOMEFIL"		, "" , "Nome Fil."   , "@!" } )
   aAdd( _aCamposTela , {"CLIENTE"		, "" , "Cliente"	   , "@!" } )
   aAdd( _aCamposTela , {"LOJA"		   , "" , "Loja"		   , "@!" } )
   aAdd( _aCamposTela , {"NOME"		   , "" , "Nome"		   , "@!" } )
   aAdd( _aCamposTela , {"REDE"		   , "" , "Rede"	      , "@!" } )
   aAdd( _aCamposTela , {"CGC"			, "" , "CNPJ"		   , "@R! NN.NNN.NNN/NNNN-99" } )
   aAdd( _aCamposTela , {"TITU"		   , "" , "Nr.Tilulo"	, "@!" } )
   aAdd( _aCamposTela , {"PARCELA"		, "" , "Parcela"	   , "@!" } )
   aAdd( _aCamposTela , {"CONDI"		   , "" , "Cond.Pgto" 	, "@!" } )
   aAdd( _aCamposTela , {"DCONDI"		, "" , "Dias Cond."	, "@!" } )
   aAdd( _aCamposTela , {"VALOR"		   , "" , "Valor"		   , "@E 99,999,999,999,999.99" } )
   aAdd( _aCamposTela , {"VENCTO"		, "" , "Vencimento"	, "@D" } )
   aAdd( _aCamposTela , {"VENCREA"		, "" , "Vencto.Real" , "@D" } )
   aAdd( _aCamposTela , {"VENCNVO"		, "" , "Novo Vencto" , "@D" } )
   aAdd( _aCamposTela , {"SITUACAO"	   , "" , "Situação"	   , "@!" } )
   aAdd( _aCamposTela , {"OBSERVACAO"	, "" , "Observação"	, "@!" } )
   aAdd( _aCamposTela , {"HISTORICO"	, "" , "Historico"	, "@!" } )
   
   _bOk     := {|| _lRet := .T., _oDlgTit:End()}
   _bCancel := {|| _lRet := .F., _oDlgTit:End()}

   aAdd(_aButtons,{"",{|| U_MFIN014M("T") }                         ,"Marc/Des"      ,"Marca/Desmarca Todos"    })
   aAdd(_aButtons,{"",{|| U_MFIN014T() }                            ,"Pesquisar"     ,"Pesquisar"               })
   aAdd(_aButtons,{"",{|| U_MFIN014R((cAliasAux)->REGSE1 )}         ,"Consultar"     ,"Consultar Título"        })
   aAdd(_aButtons,{"",{|| FWMsgRun( ,{|oproc| U_MFIN014B(oproc) })} ,"Atualiza Tit." ,"Atualiza Data do Titulo" })

   (cAliasAux)->(DBGoTop())

   _cTitulo := TITULO + " - " + "Atualização de Vencimentos "

   //======================================================
   // Configurações iniciais
   //======================================================
   _aObjects := {} 
   aAdd( _aObjects, { 315,  50, .T., .T. } )
   aAdd( _aObjects, { 100, 100, .T., .T. } )

   _aInfo := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 } 

   _aPosObj := MsObjSize( _aInfo, _aObjects, .T. ) 

   //================================================================================
   // Monta a tela de dados com MSSELECT.
   //================================================================================      
   Define MsDialog _oDlgTit Title _cTitulo From 0,0 To  _aSizeAut[6], _aSizeAut[5] Of oMainWnd   PIXEL  

      //_oMarkTitulo := MsSelect():New(cAliasAux,"MARCA","",_aCamposTela,@_lInverte, @_cMarca,{_aSizeAut[7]+20, 5, _aSizeAut[4], _aSizeAut[3]})
      _oMarkTitulo := MsSelect():New(cAliasAux ,"MARCA","",_aCamposTela,@_lInverte, @_cMarca,{20, 5,_aSizeAut[6]-60, _aSizeAut[5]-40})
      _oMarkTitulo:bAval := {|| U_MFIN014M("P")}
      _oDlgTit:lMaximized:=.T.
      
   Activate MsDialog _oDlgTit On Init (EnchoiceBar(_oDlgTit,_bOk,_bCancel,,_aButtons), _oMarkTitulo:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT , _oMarkTitulo:oBrowse:Refresh() )

   U_ITMsg( "Rotina de atualização de vencimentos de títulos finalizada!","Atenção",,2)

End Sequence 

If Select(cAliasAux) > 0
   (cAliasAux)->( DBCloseArea() )
EndIf

Return _lRet  

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/03/2014
Descrição---------: Rotina de construção do menu
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina	:= {}

ADD OPTION aRotina Title 'Consultar'	Action 'U_MFIN014R( (cAliasAux)->REGSE1 )'															  		OPERATION 2 ACCESS 0

Return( aRotina )

/*
===============================================================================================================================
Programa----------: MFIN014CNS
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/03/2014
Descrição---------: Rotina de consulta do cadastro completo do Cliente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function MFIN014R( nRegSe1 )

Private cCadastro := "Título a receber"

DBSelectArea("SE1")
SE1->( DBGoTo(nRegSE1) )
AxVisual( "SE1" , nRegSE1 , 2 )

Return

/*
===============================================================================================================================
Programa----------: MFIN014CPS
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/03/2014
Descrição---------: Define a criação de campos para exibição da análise
Parametros--------: Nenhum
Retorno-----------: aRet - Campos que serão criados e exibidos na tela
===============================================================================================================================
*/
Static Function MFIN014CPS()

Local _aCpos := {}

aAdd( _aCpos , { "MARCA"		, "C" , 2							   , 0 } )
aAdd( _aCpos , { "FILIAL"		, "C" , TamSX3("A1_FILIAL")[01]	, 0 } )
aAdd( _aCpos , { "NOMEFIL"		, "C" , 20                  		, 0 } )
aAdd( _aCpos , { "CLIENTE"		, "C" , TamSX3("A1_COD")[01]		, 0 } )
aAdd( _aCpos , { "LOJA"			, "C" , TamSX3("A1_LOJA")[01]		, 0 } )
aAdd( _aCpos , { "NOME"			, "C" , TamSX3("A1_NOME")[01]		, 0 } )
aAdd( _aCpos , { "REDE"			, "C" , TamSX3("ACY_DESCRI")[01]	, 0 } )
aAdd( _aCpos , { "CGC"			, "C" , 20 , 0 } )
aAdd( _aCpos , { "TITU"		   , "C" , 9  , 0 } )
aAdd( _aCpos , { "PARCELA"		, "C" , 3  , 0 } )
aAdd( _aCpos , { "CONDI"		, "C" , 5  , 0 } )
aAdd( _aCpos , { "DCONDI"		, "C" , 20 , 0 } )
aAdd( _aCpos , { "VALOR"		, "N" , 18 , 2 } )
aAdd( _aCpos , { "VENCTO"		, "D" , 8  , 0 } )
aAdd( _aCpos , { "VENCREA"		, "D" , 8  , 0 } )
aAdd( _aCpos , { "VENCNVO"		, "D" , 8  , 0 } )
aAdd( _aCpos , { "REGSE1"		, "N" , 18 , 0 } )
aAdd( _aCpos , { "SITUACAO"	, "C" , 20 , 0 } )
aAdd( _aCpos , { "OBSERVACAO"	, "C" , 150, 0 } )
aAdd( _aCpos , { "HISTORICO"	, "C" , 50 , 0 } )

Return( _aCpos )

/*
===============================================================================================================================
Programa----------: MFIN014B
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/03/2014
Descrição---------: Processa o o ajuste de vencimentos dos titulos marcados
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: aRet - Campos que serão criados e exibidos na tela
===============================================================================================================================
*/
User Function MFIN014B(oProc As Object)
Local _dVencAtu As Date
Local _dNovoVencto As Date
Local _nRegAtu	:= 0 As Numeric
Local _nTotReg	:= 0 As Numeric
Local _nRegSel	:= 0 As Numeric
Local _cNumLote := ""  As Character
Local _cHistor := ""  As Character
Local _cCodOcorr := ""  As Character
Local _cDescOcorr := ""  As Character
Local _lContinua := .F.  As Logical
Local _lSaldo := .F.  As Logical
Local _lVenc := .F. As Logical
Local _cObs := "" As Character

Begin Transaction

_cNumLote := U_ITInLote( "Z00" , "001" )

ProcRegua(_nTotReg)

//===========================================================================
//| Verifica a quantidade de Registros no Browse                            |
//===========================================================================

(cAliasAux)->(DBGoTop())

While !(cAliasAux)->(Eof()) 
	
	_nRegAtu++
   
   _cHistor := ""
   _cCodOcorr := ""
   _cDescOcorr := ""

   If ValType(oproc) = "O"
      oproc:cCaption := ("Processando... ["+ StrZero(_nRegAtu,6) +"] de ["+ StrZero(_nTotReg,6) +"]")
      ProcessMessages()
   EndIf
	
	If !Empty((cAliasAux)->MARCA) 
		
		_nRegSel++
		
		//atualiza campos do SE1
		
		DBSelectArea("SE1")
		SE1->( DBSetOrder(2) ) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
		
		If  SE1->(DBSeek((cAliasAux)->FILIAL+(cAliasAux)->CLIENTE+(cAliasAux)->LOJA+"1  "+(cAliasAux)->TITU	+AllTrim((cAliasAux)->PARCELA)))	 
         If SE1->E1_SALDO > 0 
            _lContinua := .T.
             _lSaldo   := .T.
         Else
            _lContinua := .F.
             _lSaldo   := .F.
         EndIf
		ElseIf ((cAliasAux)->PARCELA = '001' .Or. (cAliasAux)->PARCELA = '01') .And. SE1->(DBSeek((cAliasAux)->FILIAL+(cAliasAux)->CLIENTE+(cAliasAux)->LOJA+"1  "+(cAliasAux)->TITU )) .And. SE1->E1_SALDO > 0 
         If SE1->E1_SALDO > 0 
            _lContinua := .T.
             _lSaldo   := .T.
         Else
            _lContinua := .F.
             _lSaldo   := .F.
         EndIf
      Else
         _lContinua := .F.
         _lSaldo   := .T.
      EndIf

      If _lContinua 
		    _dVencAtu    := SE1->E1_VENCREA
	      _dNovoVencto := ctod(MFIN014AV((cAliasAux)->VENCNVO,(cAliasAux)->CONDI))

         If _dNovoVencto < SE1->E1_EMISSAO
            _lContinua := .F.
            _lVenc := .T.
         EndIf
      EndIf

      If _lContinua 

         If !Empty(AllTrim((cAliasAux)->HISTORICO))
            _cHistor := (cAliasAux)->HISTORICO 
         Else
            _cHistor := "VENC.REAL ALT.DE " + DToC(_dVencAtu) + " P/" + DToC(_dNovoVencto) + "."  
         EndIf

			SE1->( RecLock( "SE1" , .F. ) )
			SE1->E1_VENCREA	:= _dNovoVencto 
			SE1->E1_I_VCPOR	:= _dNovoVencto 
			SE1->E1_I_VCFLU	:= _dNovoVencto 
			SE1->E1_HIST      := _cHistor
         If !Empty(AllTrim((cAliasAux)->HISTORICO))
            SE1->E1_I_DTPRO   := _dNovoVencto
            SE1->E1_I_PRORR   := 'S'
            SE1->E1_I_CART    := '17'
         EndIf
			SE1->( MSUnLock() )

         If !Empty(AllTrim((cAliasAux)->HISTORICO))
            If SE1->E1_PORTADO $ "001|341"
               _cCodOcorr := "06"
               _cDescOcorr := "ALTERACAO DE VENCIMENTO"
            ElseIf SE1->E1_PORTADO == "237"
               _cCodOcorr := "31"
               _cDescOcorr := "ALTERACAO DE OUTROS DADOS"
            EndIf

            If !Empty(AllTrim(_cCodOcorr))
               //ADICAO DA INCLUSÃO DA INSTRUCAO BANCARIA
               FI2->(RecLock("FI2",.T.))

               FI2->FI2_FILIAL := (cAliasAux)->FILIAL
               FI2->FI2_OCORR  := _cCodOcorr
               FI2->FI2_DESCOC := _cDescOcorr
               FI2->FI2_PREFIX := SE1->E1_PREFIXO
               FI2->FI2_TITULO := SE1->E1_NUM
               FI2->FI2_PARCEL := SE1->E1_PARCELA
               FI2->FI2_TIPO 	 := SE1->E1_TIPO
               FI2->FI2_CODCLI := SE1->E1_CLIENTE
               FI2->FI2_LOJCLI := SE1->E1_LOJA
               FI2->FI2_GERADO := "2"
               FI2->FI2_NUMBOR := SE1->E1_NUMBOR
               FI2->FI2_CARTEI := "1"
               FI2->FI2_DTOCOR := dDataBase
               FI2->FI2_VALANT := DToC(_dVencAtu)
               FI2->FI2_VALNOV := DToC(_dNovoVencto)
               FI2->FI2_CAMPO  := "E1_VENCREA"
               FI2->FI2_TIPCPO := "D"

               FI2->(MSUnLock())

            EndIf
         EndIf

			(cAliasAux)->( RecLock( cAliasAux , .F. ) )
			(cAliasAux)->VENCREA    := _dNovoVencto 
			(cAliasAux)->SITUACAO   := "PROCESSADO"
         (cAliasAux)->OBSERVACAO := "CAMPO VENCIMENTO REAL ALTERADO DE " + DToC(_dVencAtu) + " PARA " + DToC(_dNovoVencto) + "." 
			(cAliasAux)->( MSUnLock() )
			_oMarkTitulo:oBrowse:Refresh()
		
			//===========================================================================
			//| Grava o Item processado no Lote                                         |
			//===========================================================================
			U_ITGrLote( "Z03" , _cNumLote , { { SE1->E1_FILIAL + SE1->E1_NUM + SE1->E1_PARCELA , SToD( cDtIni ) , Date() , "1" } } , "1" )
		
		Else
         If _lVenc
            _cObs := "VENCIMENTO MENOR QUE A DATA DE EMISSAO DO TITULO: " + (cAliasAux)->TITU +", FILIAL: " + (cAliasAux)->FILIAL + ", CLIENTE: " + (cAliasAux)->CLIENTE + ", LOJA: " + (cAliasAux)->LOJA + ;
                                      ", XXXXXXXXXX: '1  ', PARA AS PARCELAS: " + AllTrim((cAliasAux)->PARCELA) + ", OU '001', OU '01'."    

         ElseIf _lSaldo
            _cObs := "NAO FOI LOCALIZADO O TITULO: " + (cAliasAux)->TITU +", FILIAL: " + (cAliasAux)->FILIAL + ", CLIENTE: " + (cAliasAux)->CLIENTE + ", LOJA: " + (cAliasAux)->LOJA + ;
                                      ", XXXXXXXXXX: '1  ', PARA AS PARCELAS: " + AllTrim((cAliasAux)->PARCELA) + ", OU '001', OU '01'."    

         Else
            _cObs := "NAO HÁ SALDO PARA O TITULO: " + (cAliasAux)->TITU +", FILIAL: " + (cAliasAux)->FILIAL + ", CLIENTE: " + (cAliasAux)->CLIENTE + ", LOJA: " + (cAliasAux)->LOJA + ;
                                      ", XXXXXXXXXX: '1  ', PARA AS PARCELAS: " + AllTrim((cAliasAux)->PARCELA) + ", OU '001', OU '01'."    
         EndIf

		   (cAliasAux)->( RecLock( cAliasAux , .F. ) )
		   (cAliasAux)->SITUACAO     := "FALHA NA ATUALIZAÇÃO"
         (cAliasAux)->OBSERVACAO   := _cObs
		   (cAliasAux)->( MSUnLock() )
		   _oMarkTitulo:oBrowse:Refresh()
			
		   U_ITGrLote( "Z03" , _cNumLote , { { SE1->E1_FILIAL + SE1->E1_NUM + SE1->E1_PARCELA , SToD( cDtIni ) , Date() , "1" } } , "2" )
			
		EndIf			
		
	EndIf
	
	(cAliasAux)->( DBSkip() )
	
EndDo
 
(cAliasAux)->( DBGoTop() )

U_ITFnLote( "Z00" , _cNumLote )

End Transaction

//===========================================================================
//| Verifica o Status geral do processamento.                               |
//===========================================================================
If _nRegSel > 0
	U_ITMsg( "Registros processados com sucesso!" , "Concluído!" ,,2)
Else

	//===========================================================================
	//| Exclui o Lote que não teve registros processados.                       |
	//===========================================================================
	DBSelectArea("Z00")
	If Z00->( DBSeek( xFilial("Z00") + _cNumLote ) )
		
		Z00->( RecLock( "Z00" , .F. ) )
		Z00->( DBDelete() )
		Z00->( MSUnLock() )
		
	EndIf
	
	U_ITMsg( "O processamento foi concluído porém nenhum registro foi selecionado para o atualização!" , "Concluído!",,3 )

EndIf

_oMarkTitulo:oBrowse:Refresh()

//oMarkBRW:Refresh()
//oMarkBRW:GoTop()

Return

/*
===============================================================================================================================
Programa----------: MFIN014CGC
Autor-------------: Josué Danich Prestes
Data da Criacao---: 02/06/2014
Descrição---------: Formatação da Máscara para CPF/CNPJ
Parametros--------: _cCGCAux - cnpj sem máscara
Retorno-----------: _cRet - cnpj com máscara
===============================================================================================================================
*/
Static Function MFIN014CGC( _cCGCAux )

Local _cRet	:= ""
Local _cAux	:= AllTrim( _cCGCAux )

If Len( _cAux	 ) > 11
	_cAux	 := PadL( _cAux	 , 14 , "0" )
	_cRet := Transform( _cAux	 , "@R! NN.NNN.NNN/NNNN-99" )
Else
	_cAux	 := PadL( _cAux	 , 11 , "0" )
	_cRet := Transform( _cAux	 , "@R 999.999.999-99" )
EndIf

Return( _cRet )

/*
===============================================================================================================================
Programa----------: MFIN014AV
Autor-------------: Josué Danich Prestes
Data da Criacao---: 02/06/2014
Descrição---------: Ajusta data de acordo com condição de pagamento para dia da semana
Parametros--------: _dvenc - data de vencimento do arquivo
					  _ccond - condição de pagamento
Retorno-----------: _dret - data de vencimento ajustada
===============================================================================================================================
*/

Static Function MFIN014AV( _dvenc, _ccond )

Local _ctipo 	:= Posicione("SE4",1,xFilial("SE4")+_ccond,"E4_TIPO")
Local _cdet	:= Posicione("SE4",1,xFilial("SE4")+_ccond,"E4_COND")
Local _adias	:= {}
Local _nI 		:= 0
Local _lsai	:= .F.

If Subs(MV_PAR02,1,1) == "2"
   If _ctipo == "4" .Or. _ctipo == "6" //tipos de condição de pagamento que tem dia determinado da semana

      _adias := StrTokArr(_cdet,",")
      
      While !( dow(_dvenc) == Val(_adias[3]) )
         _dvenc++
      EndDo
      
      _dvenc := datavalida(_dvenc)

   ElseIf _ctipo == "3"  //tipo de condição que determina dias fixos do mes para pagamento
      _adias := StrTokArr(_cdet,",")
      _lsai := .F.
      
      While Len(_adias) > 2 .And. !_lsai
         _nI := 3 
         While _nI <= Len(_adias)
            If StrZero(day(_dvenc),2) == StrZero(Val(_adias[_nI]),2)
               _lsai := .T.
               _nI := Len(_adias) + 1
            Else
               _nI++
            EndIf
         EndDo
         
         If !_lsai
            _dvenc++
         Else
            _dvenc := datavalida(_dvenc)
         EndIf
      EndDo			 
   Else
      _dvenc := datavalida(_dvenc)
   EndIf
Else
   _dvenc := datavalida(_dvenc)
EndIf

Return DToC(_dvenc)

/*
===============================================================================================================================
Programa----------: MFIN014L4
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/03/2016
Descrição---------: Faz a leitura de dados no layout unico.
Parametros--------: _nreg - número de linhas do arquivo
					oproc2 - objeto da barra de processamento
Retorno-----------: _aDados - array com dados carregados do arquivo
===============================================================================================================================
*/

Static Function MFIN014L4(_nreg,oProc2)
Local _cHistor := ""
Local _nCont 	:= 0
Local _cDados	:= ""
Local _alinha	:= {}
Local _aDados 	:= {}
Local _cNumDoc , _nNumDoc
Local _aSM0 := {}
Local _aRecnoSM0  := SM0->(Recno())

Default oProc2 := nil

SM0->(DBGoTop())

While ! SM0->(Eof())
   aAdd(_aSM0,{SM0->M0_CODFIL,SM0->M0_CGC,SM0->M0_NOMECOM})
  
   SM0->(DBSkip())
EndDo

SM0->(DBGoTo(_aRecnoSM0))

FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
FT_FSKIP()

While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
	
	_nCont++ 

	If ValType(oProc2) = "O"

      	  oProc2:cCaption := ("Processando arquivo... Lendo linha " + StrZero(_nCont,5) + " de " + StrZero(_nreg,5) + ".")
   		  ProcessMessages()
 
    EndIf
			
	_cDados := FT_FREADLN()

	_alinha := U_ITTXTARRAY(_cDados,";",8) // U_MFIN014S(_cDados,";") 

	If Empty(_alinha)
	   FT_FSKIP()
	   Loop
	EndIf

    // Numero de colunas a serem lidas do arquivo texto.
    //        1              2            3             4               5               6        7
    //"CNPJ_FORNECEDOR;CODIGO_CLIENTE;NOME_CLIENTE;NUMERO_DOCUMENTO;PARCELA;VALOR_DOCUMENTO;NOVO_VENCIMENTO"
    _alinha[1] := StrTran(_alinha[1],".","")
    _alinha[1] := StrTran(_alinha[1],"/","")
    _alinha[1] := StrTran(_alinha[1],"-","")

	_alinha[6] := StrTran(_alinha[6],".","")
	_alinha[6] := StrTran(_alinha[6],",",".")
	
	_cCodCli := _alinha[2]
	
	If "-" $ _alinha[4]
	   _cNumDoc := StrTran(_alinha[4],"-","")
	   _nNumDoc := Val(AllTrim(_cNumDoc))
	   _cNumDoc := StrZero(_nNumDoc,10)
	   _cNumDoc := SubStr(_cNumDoc,1,9) 
	Else
	   _cNumDoc := _alinha[4]
	   _nNumDoc := Val(AllTrim(_cNumDoc))
	   _cNumDoc := StrZero(_nNumDoc,9)
	EndIf
	
	If aScan( _aSM0, { |x| x[2] = (AllTrim(_alinha[1]))}) > 0	
		//Identifica filial
		_cfilial := _aSM0[aScan( _aSM0, { |x| x[2] = (AllTrim(_alinha[1]))})][1]
		
		_cfilial := U_ITKEY(_cfilial,"E1_FILIAL")  
		
		//Usa número do título para identificar o cliente e loja
		DBSelectArea("SE1")
		SE1->( DBSetOrder(1) ) // E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
		
		If SE1->( DBSeek( _cfilial + U_ITKEY('1',"E1_PREFIXO") + U_ITKEY(_cNumDoc,"E1_NUM") + U_ITKEY(_alinha[5],"E1_PARCELA") + U_ITKEY('NF',"E1_TIPO")) ) .And. SE1->E1_CLIENTE == _cCodCli
			If Len(_alinha) >= 8
            _cHistor := _alinha[8]
         Else
            _cHistor := ""
         EndIf

			aAdd(_aDados, {SE1->E1_NUM    ,;            											                    //01 - num titulo  // U_ITKEY(_cNumDoc,"E1_NUM") 
					       SE1->E1_PARCELA,;																			        //02 - parcela  // '01',;	
					       SE1->E1_CLIENTE,;																			        //03 - codigo do cliente
					       SE1->E1_LOJA,;																				        //04 - loja do cliente
					       Ctod(_alinha[7]),;	    													            	     //05 - data de pagamento prevista  //Ctod(_alinha[6])
					       _cfilial,;                                                                 		  //06 - filial Italac 
					       Posicione("SA1",1,xFilial("SA1") + SE1->E1_CLIENTE + SE1->E1_LOJA,"A1_CGC"),;	  //07 - CNPJ cliente	
                      _cHistor})
	    Else
	                     //{ "Filial", "Prefixo"               , "Titulo"                      , "Parcela"            ,    "Tipo"   ,           "Cliente"}
	       aAdd(_aDadosRej,{AllTrim(_alinha[1]), U_ITKEY('1',"E1_PREFIXO"), U_ITKEY(_cNumDoc,"E1_NUM"), U_ITKEY(_alinha[5],"E1_PARCELA"), U_ITKEY('NF',"E1_TIPO"), _cCodCli})
	    EndIf
	Else
                     //{ "Filial", "Prefixo"               , "Titulo"                      , "Parcela"            ,    "Tipo"   ,           "Cliente"}
       aAdd(_aDadosRej,{AllTrim(_alinha[1]), U_ITKEY('1',"E1_PREFIXO"), U_ITKEY(_cNumDoc,"E1_NUM"), U_ITKEY(_alinha[5],"E1_PARCELA"), U_ITKEY('NF',"E1_TIPO"), _cCodCli})	
	EndIf
								                     
	FT_FSKIP()
	
EndDo
	
Return _aDados

/*
===============================================================================================================================
Função----------: MFIN014M
Autor-----------: Julio de Paula Paz
Data da Criacao-: 25/10/2016
Descrição-------: Função para marcar e desmarcar todos os Titulos a serem alterados
Parametros------: _cTipoMarca = "T" = Marca e desmarca todos os registros.
                  _cTipoMarca = "P" = Marca e desmarca apena o registro posisionado.
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MFIN014M(_cTipoMarca)
Local _cSimboloMarca := Space(2)
Local _nRegAtu := (cAliasAux)->(Recno()) 

Begin Sequence          
   If Empty((cAliasAux)->MARCA )
      _cSimboloMarca := _cMarca
   Else
      _cSimboloMarca := Space(2)
   EndIf   
      
   If _cTipoMarca == "P"
      (cAliasAux)->(RecLock(cAliasAux,.F.))
      (cAliasAux)->MARCA := _cSimboloMarca 
      (cAliasAux)->(MSUnLock())
   Else
      (cAliasAux)->(DBGoTop())
      While ! (cAliasAux)->(Eof())
         (cAliasAux)->(RecLock(cAliasAux,.F.))
         (cAliasAux)->MARCA := _cSimboloMarca 
         (cAliasAux)->(MSUnLock()) 
         
         (cAliasAux)->(DBSkip())
      EndDo
   
   EndIf
           
End Sequence

(cAliasAux)->(DBGoTo(_nRegAtu)) 
_oMarkTitulo:oBrowse:Refresh()

Return

/*
===============================================================================================================================
Função----------: MFIN014T
Autor-----------: Julio de Paula Paz
Data da Criacao-: 29/08/2018
Descrição-------: Função de pesquisa de Titulos na tela.
Parametros------: Nenhum          
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MFIN014T()
Local _lRet    := .F.
Local _bOk     := {|| _lRet := .T., _oDlgPesq:End()}
Local _bCancel := {|| _lRet := .F., _oDlgPesq:End()}
Local _oDlgPesq 
Local _cFilPesq := Space(2)
Local _cNrTitulo := Space(TamSX3("E1_NUM")[1])
Local _aItens := {"Filial + Numero Titulo","Filial + Data Vencimento"} , _cItem  
Local _cTitulo
Local _dDtVencto := CTod("  /  /  ")
Local _nRegAtu := (cAliasAux)->(Recno())

Begin Sequence
   _cTitulo := TITULO + " - " + "Pesquisa de Titulos"
   //================================================================================
   // Monta a tela de dados com MSSELECT.
   //================================================================================      
   _cItem := _aItens[1]
   
   Define MsDialog _oDlgPesq Title _cTitulo From 0,0 To 20,60 Of oMainWnd 
    
      @040,005 Say "Ordem da Pesquisa" Pixel
      @040,060 ComboBox _cItem Items _aItens OF _oDlgPesq Size 80,010 PIXEL //ON CHANGE MOMS016B(_oDlgPesq)

      @060,005 Say "Filial" Pixel
      @060,060 MsGet _oFilPesq Var _cFilPesq OF _oDlgPesq Size 10,009 PIXEL Picture "@!"

      @080,005 Say "Nr.Titulo" Pixel
      @080,060 MsGet _oNrTitulo Var _cNrTitulo OF _oDlgPesq Size 50,009 PIXEL Picture "@!"

      @100,005 Say "Dt.Vencimento" Pixel
      @100,060 MsGet _oDtVencto Var _dDtVencto OF _oDlgPesq Size 50,009 PIXEL 
      
   Activate MsDialog _oDlgPesq On Init (EnchoiceBar(_oDlgPesq,_bOk,_bCancel))

   If _lRet
      If _cItem == _aItens[1]
         (cAliasAux)->(DBSetOrder(1))
         If !(cAliasAux)->(DBSeek(_cFilPesq + _cNrTitulo))
            U_ITMsg("Não foi possível localizar a Filial + Titulo informados!","Atenção", ,1) 
            (cAliasAux)->(DBGoTo(_nRegAtu))
         EndIf
      Else
         (cAliasAux)->(DBSetOrder(2))
         If !(cAliasAux)->(DBSeek(_cFilPesq + DToS(_dDtVencto)))
            U_ITMsg("Não foi possível localizar a Filial + Dt.Vencimento informados!","Atenção", ,1) 
            (cAliasAux)->(DBGoTo(_nRegAtu))
         EndIf
      EndIf   
      
      _oMarkTitulo:oBrowse:Refresh() 
   EndIf

End Sequence

Return
