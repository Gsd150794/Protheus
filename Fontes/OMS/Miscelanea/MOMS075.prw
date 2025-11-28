/*
==============================================================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
========================================================================================================================================================================================================
Antonio  - Julio Paz     - 01/10/25 - 31/10/25 - 52156 - Desenvolvimento de Rotina para Importar Planilha CSV com Dados das Verbas dos Acordos Comerciais e Inclusão Dessas Informações no Protheus.
Antonio  - Alex  Paz     - 24/10/25 - 31/10/25 - 52156 - Ajustes da Rotina para Importar Planilha CSV com Dados das Verbas dos Acordos Comerciais e Inclusão Dessas Informações no Protheus.
========================================================================================================================================================================================================
*/

#Include	"TOTVS.Ch"

#Define		TITULO	"Análise de Pagamentos previstos"

/*
===============================================================================================================================
Programa----------: MOMS075
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/10/2025
Descrição---------: Rotina de importação dos dados dos acordos comerciais e atualização de tabelas do Protheus.
Parametros--------: Nenhum
Retorno-----------: Nenhum 
===============================================================================================================================
*/

User Function MOMS075()

Begin Sequence

   Processa( {|| MOMS075INI() } , 'Aguarde!' , 'Iniciando Rotina de Importação de Dados dos Acordos Comerciais...' )

End Sequence 	
Return

/*
===============================================================================================================================
Programa----------: MOMS075INI
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/10/2025
Descrição---------: Rotina de leitura da Planilha CSV e gravação de tabela temporária.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS075INI()
Local _aParAux	    := {}
Local _aParRet	    := {}
Local _nReg		    := 0

Local _carq		    := ""

Local _lRet        := .T.  
Local nI	          := 0

Private _aFields
Private _oMarkBRW
Private _lTemDados := .F.

Begin Sequence
 
	aAdd( _aParAux , { 6 , "Selecione arquivo .CSV:", Space(150) ,"","","",080,.T.,"Todos os arquivos (*.CSV) |*.CSV","C:\",GETF_LOCALHARD+GETF_NETWORKDRIVE})
   
   For nI := 1 To Len( _aParAux )
	   aAdd( _aParRet , _aParAux[nI][03] )
   Next nI

   If !ParamBox( _aParAux , "Importa Dados dos Acordos Comerciais" , @_aParRet )
	   U_ITMsg( "Operação cancelada pelo usuário!" , "Atenção!",,1 )
	   Break // Return
   EndIf

   //=================================================================================
   // Importa a planilha e permite as alterações das datas de vencimentos.
   //=================================================================================

   ProcRegua(0)
   IncProc( "Abrindo Planilha CSV..." )

   //----------------------------------------------------------------------------------------------//
   // Layout da Planilha a ser importada.                                                          //
   //----------------------------------------------------------------------------------------------//
   //CNPJ_CLIENTE   ;CODIGO_SUBTIPO;PERIODO;PRODUTO    ;VALOR_APURADO;NUMERO_ACORDO;VENCIMENTO 
   //01257995000133 ;99            ;102025 ;99999999999;  99999999,99; 999999999   ;01/12/2025
   //01257995000133 ;99            ;102025 ;99999999999;  99999999,99; 999999999   ;01/12/2025
   //01257995000133 ;99            ;102025 ;99999999999;  99999999,99; 999999999   ;01/12/2025
   //01257995000133 ;99            ;102025 ;99999999999;  99999999,99; 999999999   ;01/12/2025
   //01257995000133 ;99            ;102025 ;99999999999;  99999999,99; 999999999   ;01/12/2025
   //01257995000133 ;99            ;102025 ;99999999999;  99999999,99; 999999999   ;01/12/2025
   //01257995000133 ;99            ;102025 ;99999999999;  99999999,99; 999999999   ;01/12/2025
   //----------------------------------------------------------------------------------------------//

   If (Upper(Right(AllTrim(MV_PAR01),4))) == ".CSV" 

      _carq := AllTrim(MV_PAR01)

      If FT_FUSE(_carq) == -1
         U_ITMsg("1-Falha ao abrir o arquivo: "+_carq,;
                 "Erro Abertura de Arquivo",;
	             "Verfifique se o arquivo não está sendo utilizado por outro aplicativo, ou se o arquivo foi salvo corretamente no formato CSV e possui ponto-e-virgula (;) como separador de colunas.",1)
	      _lRet := .F.
	      Break
	   EndIf 
	          
      FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
      _cDados := FT_FREADLN()
      _cDados := Upper(AllTrim(_cDados))
      _cDados := StrTran(_cDados," ","") 
   
      If !("CNPJ_CLIENTE;CODIGO_SUBTIPO;PERIODO;PRODUTO;VALOR_APURADO;NUMERO_ACORDO;VENCIMENTO" $ SubStr(_cDados,1,100))
	     U_ITMsg("Layout de arquivo inválido, contido no arquivo: "+_carq,;
                 "Layout de Arquivo",;
		         "O layout do arquivo a ser processado, obrigatoriamente precisa seguir o padrão de colunas: "+CRLF+;
		         "CNPJ_CLIENTE;CODIGO_SUBTIPO;PERIODO;PRODUTO;VALOR_APURADO;NUMERO_ACORDO;VENCIMENTO;",1)
	     _lRet := .F.
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

   If FT_FUSE(MV_PAR01) == -1
      U_ITMsg("1-Falha ao abrir o arquivo: "+_carq,;
              "Erro Abertura de Arquivo",;
	          "Verfifique se o arquivo não está sendo utilizado por outro aplicativo, ou se o arquivo foi salvo corretamente no formato CSV e possui ponto-e-virgula (;) como separador de colunas.",1)
      _lRet := .F. 
      Break
   EndIf 

   FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
	
   _nReg:= FT_FLASTREC()

   ProcRegua(_nReg)
	
   FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
	
   If _nReg == 0 //O arquivo informado nao possui nenhuma linha de dados
		
      U_ITMsg("O arquivo informado para relizar a importação não possui dados.",;
	          "Arquivo inválido","Favor verificar se o arquivo informado esta correto.",1)
      _lRet := .F. 
      Break
   EndIf

   Processa( {|| U_MOMS075A(_nReg) } , 'Aguarde!' , 'Criando tabelas temporárias...' )
   
   FT_FUSE() // Fecha a planilha CSV.

   If ! _lTemDados
      U_ITMsg( "Não foi possível ler os dados da planilha CSV.","Atenção",,1)
      Break
   EndIf 

   _aFields := {}

   Aadd(_aFields   ,{"CNPJ Cliente"      , {|| TRBZK1->WK_CNPJ}    , "C" , "@R ##.###.###/####-##",1,14,0}) 
   Aadd(_aFields   ,{"Código do Subtip"  , {|| TRBZK1->ZK1_SUBITE} , "C" , "@!"                   ,0,16,0}) 
   Aadd(_aFields   ,{"Período"           , {|| TRBZK1->ZK1_ANOMES} , "C" , "@R 99/9999"           ,0,08,0}) 
   Aadd(_aFields   ,{"Produto"           , {|| TRBZK1->ZK2_PRODUT} , "C" , "@!"                   ,1,15,0}) 
   Aadd(_aFields   ,{"Valor Apurado"     , {|| TRBZK1->ZK2_VRFATM} , "N" , "@E 999,999,999,999.99",2,16,2}) 
   Aadd(_aFields   ,{"Número do Acordo"  , {|| TRBZK1->ZK3_CONTRA} , "C" , "@!"                   ,1,09,0}) 
   Aadd(_aFields   ,{"Vencimento"        , {|| TRBZK1->ZK3_VENCTO} , "D" ,                        ,0,08,0}) 
   Aadd(_aFields   ,{"Status"            , {|| TRBZK1->WK_STATUS}  , "C" , "@!"                   ,1,01,0}) 
   Aadd(_aFields   ,{"Observação"        , {|| TRBZK1->WK_OBSERV}  , "C" , "@!"                   ,1,80,0}) 

   _oMarkBRW := FWMarkBrowse():New()		   												// Inicializa o Browse
   _oMarkBRW:SetAlias( "TRBZK1")			   											// Define Alias que será a Base do Browse
   _oMarkBRW:SetDescription( "01-Tudo com Emissão Dentro do Mês - Sintético")	// Define o titulo do browse de marcacao
   _oMarkBRW:SetFields(_aFields)													 		// Campos para exibição
   _oMarkBRW:AddButton( "Gravar dados no Protheus" , {|| Processa( {|| U_MOMS075B(_nReg) } , "Gravando Dados no Protheus..." , "Aguarde!" ) } ,, 4 )                                                // Define o objeto da tela onde os dados serão exibidos
   _oMarkBRW:AddLegend('WK_STATUS == "R" ', 'RED'  , "Rejeitado")
   _oMarkBRW:AddLegend('WK_STATUS == "P" ', 'GREEN', "Aguardando processamenteo")
   _oMarkBRW:AddLegend('WK_STATUS == "A" ', 'BLUE' , "Atualizado com sucesso no Protheus")
   _oMarkBRW:Activate()			

//   U_ITMsg( "Rotina de importação de planilha CSV com os dados dos Arcordos Comerciais finalizada!","Atenção",,2)

End Sequence 

If Select("TRBZK1") <> 0
	TRBZK1->(dbCloseArea())
EndIf


Return _lRet  

/*
===============================================================================================================================
Função-------------: MOMS075A
Autor--------------: Julio de Paula Paz
Data da Criacao----: 01/10/2025
Descrição----------: Cria as tabelas temporárias da rotina e grava os dados da planilha na tabela temporária.
Parametros---------: _nTotRegs = Total de registros a serem processados.
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MOMS075A(_nTotRegs)
Local _aStruct := {}
Local _otemp
Local _cDados
Local _alinha
Local _nAux
Local _cSubTipo
Local _cAcordo
Local _cPeriodo
Local _cStatus
Local _cObserv
Local _nI

Begin Sequence

   Aadd(_aStruct ,{"WK_CNPJ"    , "C",	14 ,0}) //	CNPJ do Cliente 
   Aadd(_aStruct ,{"ZK1_SUBITE" , "C",	Getsx3cache("ZK1_SUBITE" ,"X3_TAMANHO"),0}) //	Código do Subtipo 
   Aadd(_aStruct ,{"ZK1_ANOMES" , "C",	Getsx3cache("ZK1_ANOMES" ,"X3_TAMANHO"),0}) //	Período
   Aadd(_aStruct ,{"ZK2_PRODUT" , "C",	Getsx3cache("ZK2_PRODUT" ,"X3_TAMANHO"),0}) //	Produto
   Aadd(_aStruct ,{"ZK2_VRFATM" , "N", Getsx3cache("ZK2_VRFATM" ,"X3_TAMANHO"),Getsx3cache("ZK2_VRFATM","X3_DECIMAL")}) //	Valor Apurado
   Aadd(_aStruct ,{"ZK3_CONTRA" , "C",	Getsx3cache("ZK3_CONTRA" ,"X3_TAMANHO"),0}) //	Número do Acordo
   Aadd(_aStruct ,{"ZK3_VENCTO" , "D",	8 ,0}) //	Vencimento
   Aadd(_aStruct ,{"WK_STATUS"  , "C",	1 ,0}) //	Status
   Aadd(_aStruct ,{"WK_OBSERV"  , "C",	80,0}) //	Observação


   If Select("TRBZK1") <> 0
	   TRBZK1->(dbCloseArea())
   EndIf

   _otemp := FWTemporaryTable():New( "TRBZK1", _aStruct)

   _otemp:AddIndex( "01", {"WK_CNPJ"  , "ZK1_SUBITE","ZK1_ANOMES","ZK2_PRODUT"} )
   _otemp:AddIndex( "02", {"WK_STATUS", "WK_CNPJ"   ,"ZK1_SUBITE","ZK1_ANOMES","ZK2_PRODUT"} )
   _otemp:Create()
   
   FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
   FT_FSKIP()

   ZK3->(DbSetOrder(2)) // ZK3_FILIAL+ZK3_CONTRA+ZK3_PARCEL
   SA1->(DbSetOrder(3)) // A1_FILIAL+A1_CGC

   ProcRegua(_nTotRegs)
   _nI := 1

   Do While ! FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
	   IncProc("Lendo dados da Planilha: "+AllTrim(Str(_nI, 6)) + "/" + AllTrim(Str(_nTotRegs,6)))			
	   
      _cDados := FT_FREADLN()

	   _alinha := U_ITTXTARRAY(_cDados,";",7) 

	   If Empty(_alinha)
	      FT_FSKIP()
	      Loop
	   EndIf

      If Empty(_alinha[1])
	      FT_FSKIP()
	      Loop
	   EndIf

      // Numero de colunas a serem lidas do arquivo texto.
      //        1              2           3     4          5            6           7
      ////CNPJ_CLIENTE;CODIGO_SUBTIPO;PERIODO;PRODUTO;VALOR_APURADO;NUMERO_ACORDO;VENCIMENTO 
      _alinha[1] := StrTran(_alinha[1],".","")
      _alinha[1] := StrTran(_alinha[1],"/","")
      _alinha[1] := StrTran(_alinha[1],"-","")

	   _alinha[3] := StrTran(_alinha[3],"/","")
	   
      _alinha[5] := StrTran(_alinha[5],".","")
	   _alinha[5] := StrTran(_alinha[5],",",".")
	
      If Empty(_alinha[2])
         _nAux := 2  // Considerar subtipo = 2 se não for informado na planilha.
      Else 
         _nAux := Val(AllTrim(_alinha[2]))
      EndIf 

      _cSubTipo := StrZero(_nAux,2)
      
      _nAux := Val(AllTrim(_alinha[3]))
      _cPeriodo :=  StrZero(_nAux,6)

      If Len(AllTrim(_alinha[6])) > 9
         _cAcordo := Right(_alinha[6],9)
      ElseIf Empty(_alinha[6])
         _cAcordo := Space(6)
      Else
         _nAux := Val(AllTrim(_alinha[6]))
         _cAcordo := StrZero(_nAux,9)
      EndIf                    

      //If ZK3->(MsSeek(xFilial("ZK3")+_cAcordo))
      //   _cStatus := "R"
      //   _cObserv := "Rejeitado - Já existe um acordo cadastrado com esse Numero."
      //Else
         _cStatus := "P"
         _cObserv := "Pendente - Dados pendentes de importação para o Protheus."
      //EndIf 

      If ! SA1->(MsSeek(xFilial("SA1")+_alinha[1])) // CNPJ do Cliente 
         _cStatus := "R"
         _cObserv := "Rejeitado - O CNPJ informado não existe no Protheus."
      EndIf 
      
      TRBZK1->(DbAppend())
      TRBZK1->WK_CNPJ    := _alinha[1] // CNPJ do Cliente 
      TRBZK1->ZK1_SUBITE := _cSubTipo  // Código do Subtipo 
      TRBZK1->ZK1_ANOMES := _cPeriodo  //	Período
      TRBZK1->ZK2_PRODUT := _alinha[4] //	Produto
      TRBZK1->ZK2_VRFATM := Val(Alltrim(_alinha[5])) //	Valor Apurado
      TRBZK1->ZK3_CONTRA := _cAcordo   //	Número do Acordo
      TRBZK1->ZK3_VENCTO := Ctod(AllTrim(_alinha[7])) //	Vencimento
      TRBZK1->WK_STATUS  := _cStatus   //	Status
      TRBZK1->WK_OBSERV  := _cObserv   //	Observação

      _lTemDados := .T.

	   FT_FSKIP()
	
   EndDo

End Sequence

Return Nil

/*
===============================================================================================================================
Função-------------: MOMS075B
Autor--------------: Julio de Paula Paz
Data da Criacao----: 01/10/2025
Descrição----------: Cria as tabelas temporárias da rotina e grava os dados da planilha na tabela temporária.
Parametros---------: _nTotRegs = Total de registros a serem processados.
Retorno------------: Nenhum
===============================================================================================================================
*/
User Function MOMS075B(_nTotRegs)
Local _cCodigo 
Local _cCoordena
Local _cGerente
Local _cNomeVend
Local _cChaveZK1
Local _nValTot 
Local _cContrato
Local _dVencto
Local _cSubTipo
Local _cPeriodo
Local _cCodProd 
Local _nAux

Begin Sequence
   If ! U_ITMsg("Confirma a importação e gravação dos dados dos acordos comerciais para o Protheus?","Atenção" , , ,2, 2)
      Break 
   EndIf 

   TRBZK1->(DbSetOrder(2))
   TRBZK1->(MsSeek("P"))
   If TRBZK1->(Eof())
      Break
   EndIf

   SA1->(DbSetOrder(3))
   SA3->(DbSetOrder(1))

   SA1->(Msseek(xFilial("SA1")+TRBZK1->WK_CNPJ))

   SA3->(Msseek(xFilial("SA3")+SA1->A1_VEND))
   _cCoordena := SA3->A3_SUPER  
   _cGerente  := SA3->A3_GEREN
   _cNomeVend := SA3->A3_NOME

   Begin Transaction

      _cCodigo := GETSXENUM("ZK1","ZK1_CODIGO")
      ConfirmSX8()

      _cChaveZK1 := TRBZK1->WK_CNPJ + TRBZK1->ZK3_CONTRA
      _cContrato := TRBZK1->ZK3_CONTRA
      _dVencto   := TRBZK1->ZK3_VENCTO
      _cSubTipo  := TRBZK1->ZK1_SUBITE 
      _cPeriodo  := TRBZK1->ZK1_ANOMES 

      ZK1->(RecLock("ZK1", .T.))
      ZK1->ZK1_FILIAL  := xFilial("ZK1")
      ZK1->ZK1_CODIGO  := _cCodigo// Código do Acordo
      ZK1->ZK1_STATUS  := "1" // 1 – Em Elaboração 
      ZK1->ZK1_FAVORE  := SA1->A1_COD  // A1_COD (Conforme Retorno do CNPJ digitado) 
      ZK1->ZK1_FAVLOJ  := SA1->A1_LOJA // A1_LOJA (Conforme Retorno do CNPJ digitado) 
      ZK1->ZK1_CLIENT  := SA1->A1_COD
      ZK1->ZK1_CLILOJ  := SA1->A1_LOJA
      ZK1->ZK1_TIPOAC  := "8" // 8 – Acordo Comercial 
      ZK1->ZK1_FORPAG  := "2" // 2 – Desconto 
      ZK1->ZK1_CGEREN  := _cGerente // Conforme Retorno do CNPJ Digitado (SA1) 
      ZK1->ZK1_GERENT  := Posicione("SA3",1,xFilial("SA3")+_cGerente,"A3_NOME") // Nome do Gerente (SA3) 
      ZK1->ZK1_CCOODN  := _cCoordena // Conforme Retorno do CNPJ Digitado (SA3->A3_SUPER) 
      ZK1->ZK1_COODNA  := Posicione("SA3",1,xFilial("SA3")+_cCoordena,"A3_NOME")// Nome do Coordenador (SA3) 
      ZK1->ZK1_CVENDE  := SA1->A1_VEND           // Conforme Retorno do CNPJ Digitado (SA3->A3_GEREN) 
      ZK1->ZK1_VENDER  := _cNomeVend             // Nome do Vendedor 
      ZK1->ZK1_INCLDT  := dDataBase              // Data logada no sistema (DDTABASE) 
      ZK1->ZK1_INCUSE  := UsrFullName(__cUserId) // Usuário Logado 
      ZK1->ZK1_SUBITE  := _cSubTipo              // Código do Subtipo 
      ZK1->ZK1_ANOMES  := _cPeriodo
      ZK1->ZK1_ABATIM  := "2"
      ZK1->ZK1_PROV    := "S"
      ZK1->ZK1_FORAPU  := "1"
      ZK1->(MsUnLock())
      _nValTot := 0

      Do While ! TRBZK1->(Eof()) .And. TRBZK1->WK_STATUS == "P"
         
         If _cChaveZK1 <> TRBZK1->WK_CNPJ + TRBZK1->ZK3_CONTRA
         
           //===============================================
           // Grava a ZK3 do Cliente e/ou contrato anterior
           //===============================================
            ZK3->(RecLock("ZK3",.T.))
            ZK3->ZK3_FILIAL := xFilial("ZK3")
            ZK3->ZK3_CODIGO := _cCodigo
            ZK3->ZK3_VALOR  := _nValTot
            ZK3->ZK3_VENCTO := _dVencto
            If !Empty(_cContrato )
               ZK3->ZK3_CONTRA := _cContrato 
            Else
               _nAux := Val(AllTrim(_cCodigo))
               ZK3->ZK3_CONTRA := StrZero(_nAux,9)
            EndIf
            ZK3->(MsUnlock())

            //===========================================================
            // Inicializa as variáveis para o novo Contrato e/ou Cliente
            //===========================================================
            _cCodigo := GETSXENUM("ZK1","ZK1_CODIGO")
            ConfirmSX8()

            _cChaveZK1 := TRBZK1->WK_CNPJ + TRBZK1->ZK3_CONTRA
            _cContrato := TRBZK1->ZK3_CONTRA
            _dVencto   := TRBZK1->ZK3_VENCTO
            _cSubTipo  := TRBZK1->ZK1_SUBITE 
            _cPeriodo  := TRBZK1->ZK1_ANOMES 

            SA1->(Msseek(xFilial("SA1")+TRBZK1->WK_CNPJ))

            SA3->(Msseek(xFilial("SA3")+SA1->A1_VEND))
            _cCoordena := SA3->A3_SUPER  
            _cGerente  := SA3->A3_GEREN
            _cNomeVend := SA3->A3_NOME
            _cSubTipo  := TRBZK1->ZK1_SUBITE 

            //================================================
            // Atualiza ZK1 antes de criar um novo registro
            //================================================
            ZK1->(RecLock("ZK1", .F.))
            ZK1->ZK1_VLRCOR  := _nValTot
            ZK1->(MsUnLock())

            //=======================================================================
            // Cria um novo registro na tabela ZK1 (Novo Contrato e/ou novo Cliente)
            //=======================================================================
            ZK1->(RecLock("ZK1", .T.))
            ZK1->ZK1_FILIAL  := xFilial("ZK1")
            ZK1->ZK1_CODIGO  := _cCodigo// Código do Acordo
            ZK1->ZK1_STATUS  := "1" // 1 – Em Elaboração 
            ZK1->ZK1_FAVORE  := SA1->A1_COD  // A1_COD (Conforme Retorno do CNPJ digitado) 
            ZK1->ZK1_FAVLOJ  := SA1->A1_LOJA // A1_LOJA (Conforme Retorno do CNPJ digitado) 
            ZK1->ZK1_CLIENT  := SA1->A1_COD
            ZK1->ZK1_CLILOJ  := SA1->A1_LOJA
            ZK1->ZK1_TIPOAC  := "8" // 8 – Acordo Comercial 
            ZK1->ZK1_FORPAG  := "2" // 2 – Desconto 
            ZK1->ZK1_CGEREN  := _cGerente // Conforme Retorno do CNPJ Digitado (SA1) 
            ZK1->ZK1_GERENT  := Posicione("SA3",1,xFilial("SA3")+_cGerente,"A3_NOME") // Nome do Gerente (SA3) 
            ZK1->ZK1_CCOODN  := _cCoordena // Conforme Retorno do CNPJ Digitado (SA3->A3_SUPER) 
            ZK1->ZK1_COODNA  := Posicione("SA3",1,xFilial("SA3")+_cCoordena,"A3_NOME")// Nome do Coordenador (SA3) 
            ZK1->ZK1_CVENDE  := SA1->A1_VEND           // Conforme Retorno do CNPJ Digitado (SA3->A3_GEREN) 
            ZK1->ZK1_VENDER  := _cNomeVend             // Nome do Vendedor 
            ZK1->ZK1_INCLDT  := dDataBase              //  Data logada no sistema (DDTABASE) 
            ZK1->ZK1_INCUSE  := UsrFullName(__cUserId) //  Usuário Logado 
            ZK1->ZK1_SUBITE  := _cSubTipo              // Código do Subtipo 
            ZK1->ZK1_ANOMES  := _cPeriodo
            ZK1->ZK1_ABATIM  := "2"
            ZK1->ZK1_PROV    := "S"
            ZK1->ZK1_FORAPU  := "1"
            ZK1->(MsUnLock())
 
            _nValTot := 0

         EndIf 
         
         _cCodProd := Upper(TRBZK1->ZK2_PRODUT)

         ZK2->(RecLock("ZK2",.T.))
         ZK2->ZK2_FILIAL := xFilial("ZK2")
         ZK2->ZK2_CODIGO := _cCodigo
         ZK2->ZK2_PRODUT := TRBZK1->ZK2_PRODUT
         If "G" $ _cCodProd
            ZK2->ZK2_DESCRI := "GRUPO MIX"
         Else 
            ZK2->ZK2_DESCRI := Posicione("SB1",1,xFilial("SB1")+TRBZK1->ZK2_PRODUT,"B1_DESC")
         EndIf 
         ZK2->ZK2_VRFATM := TRBZK1->ZK2_VRFATM
         ZK2->ZK2_VEND1  := SA1->A1_VEND
         ZK2->ZK2_TIPREG := "I"
         ZK2->ZK2_TIPOAC := "8"
         ZK2->(MsUnLock())
         
         _nValTot += TRBZK1->ZK2_VRFATM

         TRBZK1->WK_STATUS  := "A"   //	Status
         TRBZK1->WK_OBSERV  := "Atualizado - Acordo incluido no Protheus"   //	Observação

         TRBZK1->(DbSkip())
      EndDo 

      //================================================
      // Atualiza o ultimo ZK1 Criado.
      //================================================
      ZK1->(RecLock("ZK1", .F.))
      ZK1->ZK1_VLRCOR  := _nValTot
      ZK1->(MsUnLock())

      ZK3->(RecLock("ZK3",.T.))
      ZK3->ZK3_FILIAL := xFilial("ZK3")
      ZK3->ZK3_CODIGO := _cCodigo
      ZK3->ZK3_VALOR  := _nValTot
      ZK3->ZK3_VENCTO := _dVencto
      If !Empty(_cContrato )
         ZK3->ZK3_CONTRA := _cContrato 
      Else
         _nAux := Val(AllTrim(_cCodigo))
         ZK3->ZK3_CONTRA := StrZero(_nAux,9)
      EndIf
      ZK3->(MsUnlock())

   End Transaction 
   
   TRBZK1->(DbGotop())
   _oMarkBRW:Refresh()
   
End Sequence

Return Nil
