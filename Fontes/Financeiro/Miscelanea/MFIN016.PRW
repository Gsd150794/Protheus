/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |10/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25. 
Jonathan      |01/10/2020| Chamado 33566. Ajuste na compensação da DTC com a NF. 
Alex Wallauer |23/05/2023| Chamado 43841. Ajuste para efetuar a baixa da NF com a NCC a maior com variação até 0,02. 
Jose Gavetti  |26/11/2025| Chamado 51341. cEmpAnt não deve ter seu conteúdo alterado orientação TOTVS.
===============================================================================================================================
*/

#Include	"Protheus.Ch"

/*
===============================================================================================================================
Programa----------: MFIN016
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 28/05/2019
Descrição---------: Rotina de Leitura e compensacao titulos - Chamado 29364
Retorno-----------: Nenhum  
===============================================================================================================================
*/
User Function MFIN016()

Private MV_PAR01:=Space(200)
Private _cSalva_MV_PAR01 := MV_PAR01
Private  cMarca :=GetMark()

While .T.
   lSair:=.T.

   FWMsgRun( ,{|oproc| lSair:=MFIN016INI(oproc) } , "Processando..." , "Iniciando o processamento..." )

   If lSair
      Exit
   EndIf
EndDo

SET DATE FORMAT TO "DD/MM/YY"
	
Return

/*
===============================================================================================================================
Programa----------: MFIN016INI
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 19/05/2017
Descrição---------: Rotina de montagem da tela de processamento
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: .T. OU .F.
===============================================================================================================================
*/
Static Function MFIN016INI(oproc)

Local _aParAux	:= {}
Local _aParRet	:= {}
Local _aCpos	:= MFIN016CPS()
Local _nreg		:= 0
Local _aDados	:= {}
Local _nI		:= 0
Local _carq		:= ""
Local _otemp    := nil  , nI
Private cAliasAux	:= GetNextAlias()

MV_PAR01 := _cSalva_MV_PAR01
 
aAdd( _aParAux , { 1 , "Selecione arquivo:"		, MV_PAR01, "@!"		, ""	, "DIR"		, "" , 100 , .F. } ) 	//| 01 |

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next nI

If !ParamBox( _aParAux , "Leitura e compensacao de titulos DCT" , @_aParRet )
	Return .T.
EndIf

//Grava Log de execução da rotina
U_ITLOGACS( "MFIN016" )

_cSalva_MV_PAR01 := MV_PAR01

oproc:cCaption := ("Abrindo arquivo...")
ProcessMessages()

If (Upper(right(AllTrim(MV_PAR01),4))) == ".CSV" 

	_carq := AllTrim(MV_PAR01)

	If FT_FUSE(_carq) == -1
	
		U_ITMsg("1-Falha ao abrir o arquivo: "+_carq,"Erro",,1)
		
		Return .F.
		
	EndIf 
	          
  	FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO 
  	_cDados := FT_FREADLN()

  	If !"TITULO" $ Upper(AllTrim(_cDados)) .Or. !"CLIENTE" $ Upper(AllTrim(_cDados))

	    U_ITMsg("O arquivo "+_carq+" informado para relizar a importação não tem o layout padrão.",;
            "Arquivo com formato inválido",;
			"O CSV deve ter as colunas [ Titulo;Cliente ] e o mesmo deve ser salvo "+;
		    "no Excel no formato [ CSV (separado por virgulas) ] e "+;
		    "no LibreOffice Calc com Demilitador de campo Ponto e Virgula e sem delimitador de texto.",1)
	    Return .F.

  	EndIf

	//Fecha arquivo e prepara parâmetro com arquivo convertido
	FT_FUSE()

Else

	U_ITMsg("O arquivo informado: "+AllTrim(MV_PAR01)+" não tem extenção [ .CSV ] ",;
            "Arquivo inválido",;
		    "Favor informar uma arquivo no formato [ .CSV ].")
	Return .F.

EndIf


If .T.

	If FT_FUSE(_carq) == -1
		
		U_ITMsg("2-Falha ao abrir o arquivo: "+_carq,"Erro",,1)
		Return .F.

	EndIf
	
	FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
	
	_nReg:= FT_FLASTREC()

	ProcRegua(_nReg)
	
	FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
	
	If _nReg == 0 //O arquivo informado nao possui nenhuma linha de dados
		
		U_ITMsg("O arquivo informado para relizar a importação não possui dados.",;
                "Arquivo inválido",;
				"Favor verificar se o arquivo informado esta no formato correto.")
		Return .F.
	
	EndIf

	
	_aDados := MFIN016L(_nreg,oproc) //Faz leitura dos dados
	

	If Len(_aDados) <= 0

		U_ITMsg( "Não foram encontrados registros válidos no arquivo!" , "Atenção!",,1 )
		Return .F.
	
	EndIf
	
EndIf

//================================================================================
// Verifica se ja existe um arquivo com mesmo nome, SE SIM DELETA 
//================================================================================
If Select(cAliasAux) > 0
	oproc:cCaption := ("Apagando temporário...")
	ProcessMessages()
	_otemp:Delete()
EndIf

oproc:cCaption := ("Criando arquivo temporário...")
ProcessMessages()
_otemp := FWTemporaryTable():New( cAliasAux, _aCpos )

oproc:cCaption := ("Criando indices do arquivo temporário...")
ProcessMessages()

_otemp:AddIndex( "01", {"FILIAL","TITU","CLIENTE","WKPARCELA"} )
_otemp:Create()

_aMarcados:={}

For  _nI := 1 TO Len(_aDados)
	
	oproc:cCaption := ("Processando: "+ StrZero( _nI , 6 ) +" de "+ StrZero( Len(_aDados) , 6 ) +" Registros..." )
	ProcessMessages()
    
    If _aDados[_nI][12] # 0 // 'DCT'
	   SE1->(DBGoTo( _aDados[_nI][12] ))//POSICIONA NO SE1
	   If (cAliasAux)->( DBSeek(SE1->E1_FILIAL+SE1->E1_NUM+SE1->E1_CLIENTE+SE1->E1_PARCELA) )
         (cAliasAux)->WKPARCDCT := SE1->E1_PARCELA
 	      (cAliasAux)->SALDO	  := SE1->E1_SALDO
	      (cAliasAux)->E1_TIPO   := SE1->E1_TIPO
	      (cAliasAux)->E1_PREFIXO:= SE1->E1_PREFIXO
     	   (cAliasAux)->LOJA 	  := SE1->E1_LOJA
         (cAliasAux)->REGSEDCT  := _aDados[_nI][12]//12 - Recno SE1 DCT
	      If (cAliasAux)->FILIAL <> cFilant
 	         (cAliasAux)->WKSTATUS:= "R"
	         (cAliasAux)->ERRO:=" [Titulo não pertence a filial atual]"//AllTrim((cAliasAux)->ERRO) + 
	      ElseIf (cAliasAux)->SALDO <= 0
 	         (cAliasAux)->WKSTATUS:= "R"
	         (cAliasAux)->ERRO    := AllTrim((cAliasAux)->ERRO) + " [Titulo DCT sem Saldo]"
	      ElseIf (cAliasAux)->SALDO > ((cAliasAux)->SALDONF+0.02)
 	         (cAliasAux)->WKSTATUS:= "R"
	         (cAliasAux)->ERRO  := AllTrim((cAliasAux)->ERRO) + " [Saldo do DCT maior que o saldo do NF]"
         ElseIf Empty((cAliasAux)->ERRO )
             If (_nPos:=aScan(_aMarcados,{|T| T[1]==(cAliasAux)->FILIAL+(cAliasAux)->TITU+(cAliasAux)->CLIENTE+(cAliasAux)->WKPARCELA  })) # 0
                If (cAliasAux)->LOJANF == (cAliasAux)->LOJA 
                   _aMarcados[_nPos,2]:=.T.
                   (cAliasAux)->MARCA := cMarca
	            Else
 	               (cAliasAux)->WKSTATUS:= "E"
	               (cAliasAux)->ERRO  := AllTrim((cAliasAux)->ERRO) + " [Titulos com Lojas diferentes]"
	            EndIf  
             EndIf
         EndIf
	      (cAliasAux)->ERRO    := AllTrim((cAliasAux)->ERRO)//Para tirar os espacos da frente
         Loop//********************************************************************/
	   Else
	      (cAliasAux)->( DBAPPEND() ) // Senão achou a NF em aberto mostra a dct mesmo assim			
	   EndIf
	Else
	   (cAliasAux)->( DBAPPEND() )
	EndIf

   (cAliasAux)->FILIAL	 := _aDados[_nI][01]
	(cAliasAux)->TITU		 := _aDados[_nI][02]
	(cAliasAux)->CLIENTE	 := _aDados[_nI][03]
   (cAliasAux)->WKPARCELA:= _aDados[_nI][04]
	(cAliasAux)->WKSTATUS := _aDados[_nI][05]
  	(cAliasAux)->ERRO   	 := _aDados[_nI][06]
	
	If _aDados[_nI][11] # 0 .Or. _aDados[_nI][12] # 0 

	  If _aDados[_nI][11] # 0 //NF
	     SE1->(DBGoTo( _aDados[_nI][11] ))//POSICIONA NO SE1
 	     (cAliasAux)->SALDONF   := SE1->E1_SALDO
	     (cAliasAux)->E1_TIPONF := SE1->E1_TIPO
	     (cAliasAux)->E1_PREFINF:= SE1->E1_PREFIXO
     	  (cAliasAux)->LOJANF	 := SE1->E1_LOJA
        (cAliasAux)->REGSENF   := _aDados[_nI][11]//11 - Recno SE1 NF
        If (cAliasAux)->SALDONF <= 0
 	        (cAliasAux)->WKSTATUS:= "R"
	        (cAliasAux)->ERRO    := AllTrim((cAliasAux)->ERRO) + " [Titulo NF sem Saldo]"
		  EndIf	
	  
	  ElseIf _aDados[_nI][12] # 0 // 'DCT'
	     SE1->(DBGoTo( _aDados[_nI][12] ))//POSICIONA NO SE1
        (cAliasAux)->WKPARCDCT := SE1->E1_PARCELA
 	     (cAliasAux)->SALDO	    := SE1->E1_SALDO
	     (cAliasAux)->E1_TIPO   := SE1->E1_TIPO
	     (cAliasAux)->E1_PREFIXO:= SE1->E1_PREFIXO
     	  (cAliasAux)->LOJA 		 := SE1->E1_LOJA
        (cAliasAux)->REGSEDCT  := _aDados[_nI][12]//12 - Recno SE1 DCT
	     If (cAliasAux)->SALDO <= 0
 	        (cAliasAux)->WKSTATUS:= "R"
	        (cAliasAux)->ERRO    := AllTrim((cAliasAux)->ERRO) + " [Titulo DCT sem Saldo]"
	     EndIf
	  EndIf
	EndIf   
	If !Empty((cAliasAux)->FILIAL) .And. (cAliasAux)->FILIAL <> cFilant
      (cAliasAux)->WKSTATUS:= "R"
      (cAliasAux)->ERRO:="[Titulo não pertence a filial atual]"
   EndIf
   (cAliasAux)->ERRO    := AllTrim((cAliasAux)->ERRO)//Para tirar os espacos da frente	   

	If aScan(_aMarcados,{|T| T[1]==(cAliasAux)->FILIAL+(cAliasAux)->TITU+(cAliasAux)->CLIENTE+(cAliasAux)->WKPARCELA }) = 0
       aAdd(_aMarcados,{(cAliasAux)->FILIAL+(cAliasAux)->TITU+(cAliasAux)->CLIENTE+(cAliasAux)->WKPARCELA ,.F., (cAliasAux)->LOJANF})
	EndIf
 
Next

_lAtivaMensagem:=.T.
MFIN16Tela(cAliasAux)
(cAliasAux)->( DBCloseArea() )

Return .F.
/*
===============================================================================================================================
Programa----------: MFIN016L
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 19/05/2017
Descrição---------: Faz a leitura de dados no layout do Atacadao
Parametros--------: _nreg - número de linhas do arquivo
				    oproc - objeto da barra de processamento
Retorno-----------: _aDados - array com dados carregados do arquivo
===============================================================================================================================
*/

Static Function MFIN016L(_nreg,oproc)

Local _nCont 	:= 0
Local _cdados	:= ""
Local _alinha	:= {}
Local _aDados 	:= {}
Local _nColTit  := 1
Local _nColCli  := 2
Local _aTiraDupl:= {}


FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
FT_FSKIP()

While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
	
	_nCont++ 
	oproc:cCaption := ( "Lendo linha " + StrZero(_nCont,5) + " de " + StrZero(_nreg,5) + "." )
	ProcessMessages()
			
	_cDados := AllTrim(FT_FREADLN())
	_aLinha := StrTokArr(_cDados,";")
	
	//Verifica se é final de arquivo
	If AllTrim(_cdados) = ';' .And. _nCont > 5
		Exit
	EndIf 	
	
	//Verifica se é linha válida
	If Len(_aLinha) < 2	
		FT_FSKIP()
		Loop		
	EndIf

	_cE1_NUM    :=StrZero(Val(_alinha[_nColTit]),Len(SE1->E1_NUM))
	_cE1_CLIENTE:=StrZero(Val(_alinha[_nColCli]),Len(SE1->E1_CLIENTE))
   If Len(_alinha) > 2
      _cParcela:=StrZero(Val(_alinha[3]),Len(SE1->E1_PARCELA))
   Else
      _cParcela:=Space(Len(SE1->E1_PARCELA))
   EndIf
	If aScan(_aTiraDupl,_cE1_NUM+_cE1_CLIENTE+_cParcela) = 0
	   aAdd(_aTiraDupl,_cE1_NUM+_cE1_CLIENTE+_cParcela)
	Else
	   FT_FSKIP()
	   Loop//IGNORA CHAVE DUPLICADAS
	EndIf
   
 	_cQuery := " SELECT  R_E_C_N_O_ REC_SE1 "
	_cQuery += " FROM " +RETSQLNAME("SE1") + " SE1 WHERE D_E_L_E_T_ = ' ' "
	_cQuery += " AND (    (E1_TIPO    = 'NF'                      )   "// AND E1_SALDO > 0 
	_cQuery += "       OR (E1_PREFIXO = 'DCT' AND E1_TIPO  = 'NCC') ) "
	_cQuery += " AND E1_NUM     = '" + _cE1_NUM + "' "
	_cQuery += " AND E1_CLIENTE = '" + _cE1_CLIENTE+"' "
// If !Empty(Val(_cParcela))
	_cQuery += " AND E1_PARCELA = '" + _cParcela + "'"
//	EndIf
	_cQuery += " ORDER BY E1_FILIAL, E1_NUM, E1_CLIENTE, E1_LOJA, E1_PARCELA ,E1_TIPO DESC "
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , "SE1T" , .T. , .F. )

	_nTotTit:=0
	COUNT TO _nTotTit
	
    _cErro:=""
    _cStatus:="A"//WKSTATUS
    _nREGSENF:= 0
    _nREGSEDCT:= 0
    SE1T->(DBGoTop())

	While !SE1T->(Eof()) .Or. _nTotTit = 0

  	   If _nTotTit > 0
         SE1->(DBGoTo(SE1T->REC_SE1))
	   Else 
	      SE1->(DBGOBOTTOM())    
		   SE1->(DBSkip())
	   EndIf  
  	   If _nTotTit <= 1
  	      If _nTotTit = 1
            If SE1->E1_TIPO == 'NF '
                _cErro:="[Titulo DCT correspondente não localizada] "
			   Else	
                _cErro:="[Titulo NF correspondente não localizada] "
			   EndIf
		   Else	 
            If !Empty(Val(_cParcela))
               _cErro:="[Nenhum Titulo encontrado para esse Cliente + parcela] "
				Else
               _cErro:="[Nenhum Titulo encontrado para esse Cliente ou titulo possui parcelas] "
				EndIf	
		   EndIf
         _cStatus:='R'
	   EndIf	  

       _nREGSENF := 0
       _nREGSEDCT:= 0
       If SE1->E1_TIPO == 'NF '
	      _nREGSENF := SE1T->REC_SE1
       ElseIf SE1->E1_TIPO == 'NCC' 
	      _nREGSEDCT:= SE1T->REC_SE1
	   EndIf	  	  

	   aAdd(_aDados,{;
					 SE1->E1_FILIAL ,;//01 - Filial Italac
		          _cE1_NUM          ,;//02 - Num titulo
					 _cE1_CLIENTE   ,;//03 - Codigo do cliente
					 _cParcela      ,;//04 - Parcela do arquivo
					 _cStatus       ,;//05 - WKSTATUS 
					 _cErro         ,;//06 - Erro 
					 SE1->E1_LOJA	,;//07 - Loja do cliente
					 SE1->E1_TIPO   ,;//08 - E1_TIPO
					 SE1->E1_PREFIXO,;//09 - Prefixo
					 SE1->E1_SALDO  ,;//10 - Saldo
					 _nREGSENF      ,;//11 - Recno SE1 NF
					 _nREGSEDCT     })//12 - Recno SE1 DCT
	    
  	   If _nTotTit = 0
  	      Exit
  	   EndIf

       _cErro:=""
	
	   SE1T->( DBSkip() )	    

	EndDo
	SE1T->( DBCloseArea() )
	
	FT_FSKIP()
	
EndDo
	
Return _aDados
/*
===============================================================================================================================
Programa----------: MFIN016CNS
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 19/05/2017
Descrição---------: Rotina de consulta do cadastro completo do Cliente
Parametros--------: _cChama: da onde chama
Retorno-----------: .T. OU .F.
===============================================================================================================================
*/

User Function MFIN016R(_cChama)
Local lRet:=.T.
Local nReg:=0

If _cChama == "MARCARALL" .Or. _cChama == "DESMARCARALL"  .Or. _cChama == "INVERTEMARCACAO"
   
   _lAtivaMensagem:=.F.
   (cAliasAux)->( DBGoTop() )
   While (cAliasAux)->(!Eof())
   	
      If (cAliasAux)->WKSTATUS $ 'A,E'
         If _cChama == "MARCARALL" 
	        (cAliasAux)->MARCA:= cMarca
		 ElseIf _cChama == "DESMARCARALL"
	        (cAliasAux)->MARCA:= ""
		 Else//INVERTEMARCACAO
	        (cAliasAux)->MARCA:= If(Empty((cAliasAux)->MARCA),cMarca,"")
		 EndIf	
         If (_nPos:=aScan(_aMarcados,{|T| T[1]==(cAliasAux)->FILIAL+(cAliasAux)->TITU+(cAliasAux)->CLIENTE+(cAliasAux)->WKPARCELA  })) # 0
            _aMarcados[_nPos,2]:=.T.
            _aMarcados[_nPos,3]:=(cAliasAux)->LOJANF
         EndIf
	  EndIf	
   	  (cAliasAux)->( DBSkip() )
   
   EndDo
   (cAliasAux)->( DBGoTop() )
   _lAtivaMensagem:=.T.
   Return .T.
EndIf

If (cAliasAux)->REGSENF = 0 .And. (_cChama == "VISUALNF" .Or. _cChama <> "VISUALDCT" )
    U_ITMsg("Titulo NF não encontrado","Atenção",,1)
   Return .F.
EndIf
If (cAliasAux)->REGSEDCT = 0  .And. (_cChama == "VISUALDCT" .Or. _cChama <> "VISUALNF" )
    U_ITMsg("Titulo DCT não encontrado","Atenção",,1)
   Return .F.
EndIf

If "VISUAL" $_cChama 
   
   If _cChama == "VISUALNF"
      cCadastro := "Titulo NF"
      SE1->( DBGoTo( (cAliasAux)->REGSENF ) )
      nReg:=(cAliasAux)->REGSENF
   ElseIf _cChama == "VISUALDCT"
      cCadastro := "Titulo DCT"
      SE1->( DBGoTo( (cAliasAux)->REGSEDCT ) )
      nReg:=(cAliasAux)->REGSEDCT
   EndIf

   DBSelectArea("SE1")
   AxVisual("SE1",nReg,2)
   Return .T.
EndIf

If (cAliasAux)->WKSTATUS = 'P'"
   U_ITMsg("Titulo já processado com sucesso","Atenção",,1)
   Return .F.
EndIf

If (cAliasAux)->WKSTATUS = 'R'"
   U_ITMsg("Titulo rejeitado na leitura do arquivo.","Atenção",,1)
   Return .F.
EndIf

If _cChama = "MARCAR"

   If Empty((cAliasAux)->MARCA) 
	  
	  If (_nPos:=aScan(_aMarcados,{|T| T[1]==(cAliasAux)->FILIAL+(cAliasAux)->TITU+(cAliasAux)->CLIENTE+(cAliasAux)->WKPARCELA  })) # 0
         If _aMarcados[_nPos,2] .And. _aMarcados[_nPos,3] <> (cAliasAux)->LOJA
            If _lAtivaMensagem
               U_ITMsg("Titulo ["+(cAliasAux)->TITU+"] já marcado na Loja: "+_aMarcados[_nPos,3],"Atenção",,1)
			EndIf   
            Return .F.
         EndIf
	  EndIf

      If (cAliasAux)->SALDO <= 0
         If _lAtivaMensagem
            U_ITMsg("Saldo da DCT zerado","Atenção",,1)
		EndIf	
         Return .F.
      EndIf

      If (cAliasAux)->SALDO > ((cAliasAux)->SALDONF+0.02)
         If _lAtivaMensagem
            U_ITMsg("Saldo do DCT maior que o saldo do NF + 0.02","Atenção",,1)
		 EndIf  
         Return .F.
      EndIf

      lRet:=.T.
      If (_nPos:=aScan(_aMarcados,{|T| T[1]==(cAliasAux)->FILIAL+(cAliasAux)->TITU+(cAliasAux)->CLIENTE+(cAliasAux)->WKPARCELA })) # 0
         _aMarcados[_nPos,2]:=.T.
         _aMarcados[_nPos,3]:=(cAliasAux)->LOJANF
      EndIf
      (cAliasAux)->WKSTATUS:='A'//Marca aceito de novo para poder altetrar e reprocessar caso tenha dado lMsErroAuto = .T.
	  (cAliasAux)->MARCA   := cMarca

   Else
     
	  (cAliasAux)->MARCA   := ""
      If (_nPos:=aScan(_aMarcados,{|T| T[1]==(cAliasAux)->FILIAL+(cAliasAux)->TITU+(cAliasAux)->CLIENTE })) # 0
         _aMarcados[_nPos,2]:=.F.
         _aMarcados[_nPos,3]:="" 
      EndIf
   
   EndIf

EndIf

DBSelectArea(cAliasAux)//Tem volta para o alias do browse pq senão dá erro

Return lRet

/*
===============================================================================================================================
Programa----------: MFIN016CPS
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 19/05/2017
Descrição---------: Define a criação de campos para exibição da análise
Retorno-----------: aRet - Campos que serão criados e exibidos na tela
===============================================================================================================================
*/
Static Function MFIN016CPS()

Local _aCpos := {}

aAdd( _aCpos , { "WKSTATUS"	    , "C" , 01, 0 } )
aAdd( _aCpos , { "MARCA"		, "C" , 02, 0 } )
aAdd( _aCpos , { "FILIAL"		, "C" , TamSX3("A1_FILIAL")[01]		, 0 } )
aAdd( _aCpos , { "CLIENTE"		, "C" , TamSX3("A1_COD")[01]		, 0 } )
aAdd( _aCpos , { "LOJA"			, "C" , TamSX3("A1_LOJA")[01]		, 0 } )
aAdd( _aCpos , { "TITU"			, "C" , 09, 0 } )
aAdd( _aCpos , { "WKPARCELA"	, "C" , 03, 0 } )
aAdd( _aCpos , { "WKPARCDCT"	, "C" , 03, 0 } )
aAdd( _aCpos , { "SALDO"  		, "N" , 18, 8 } )
aAdd( _aCpos , { "REGSENF"		, "N" , 18, 0 } )
aAdd( _aCpos , { "REGSEDCT"		, "N" , 18, 0 } )
aAdd( _aCpos , { "ERRO"	  	    , "C" , 150, 0 } )
aAdd( _aCpos , { "E1_TIPO" 	    , "C" , Len(SE1->E1_TIPO), 0 } )
aAdd( _aCpos , { "E1_PREFIXO" 	, "C" , Len(SE1->E1_PREFIXO), 0 } )
aAdd( _aCpos , { "E1_TIPONF"    , "C" , Len(SE1->E1_TIPO), 0 } )
aAdd( _aCpos , { "E1_PREFINF"   , "C" , Len(SE1->E1_PREFIXO), 0 } )
aAdd( _aCpos , { "SALDONF"  	, "N" , 18, 8 } )
aAdd( _aCpos , { "LOJANF"			, "C" , TamSX3("A1_LOJA")[01]		, 0 } )


Return( _aCpos )

/*
===============================================================================================================================
Programa----------: MFIN016B
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 19/05/2017
Descrição---------: Processa o o ajuste de vencimentos dos titulos marcados
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: NIL
===============================================================================================================================
*/
User Function MFIN016B(oproc)

Local _nRegAtu	:= 0
Local _cTotReg	:= AllTrim(Str((cAliasAux)->( LASTREC() )))
Local _nTamTot	:= Len(_cTotReg)
Local _nRegSel	:= 0
Local _nRegErro	:= 0

(cAliasAux)->( DBGoTop() )

While (cAliasAux)->( !Eof() )

	_nRegAtu++
	oproc:cCaption := ("Processando: "+ Str(_nRegAtu,_nTamTot) +" de "+ _cTotReg+" / "+Str(_nRegSel,_nTamTot)+" Compensandos" )
	ProcessMessages()
	
  	If (cAliasAux)->WKSTATUS = 'A' .And. !Empty((cAliasAux)->MARCA)
	
	   _cErro:=""
	   If MFIN13Compensar((cAliasAux)->REGSENF ,(cAliasAux)->REGSEDCT)//COMPENSAR SE1
	      (cAliasAux)->WKSTATUS:='P'
	      (cAliasAux)->ERRO  :="Titulo compensado"
	      _nRegSel++
	   Else
	      _nRegErro++
	      (cAliasAux)->WKSTATUS:='E'
	      (cAliasAux)->ERRO  :=_cErro
	   EndIf	
       (cAliasAux)->MARCA := ""//Desmarca Sempre

	EndIf	
	
	(cAliasAux)->( DBSkip() )
	
EndDo

(cAliasAux)->( DBGoTop() )

_cMen:=AllTrim(Str(_nRegAtu ))+" registro(s) processado(s)."+CHR(13)+CHR(10)
_cMen+=AllTrim(Str(_nRegSel ))+" registro(s) Compensando(s) com sucesso."+CHR(13)+CHR(10)
_cMen+=AllTrim(Str(_nRegErro))+" registro(s) com erro."

U_ITMsg(_cMen,"Concluído!",,2)

Return

/*
===============================================================================================================================
Programa----------: MFIN13Compensar()
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 29/05/2017
Descrição---------: nRecnoNF,nRecnoDCT
Retorno-----------: .T. OU .F.
===============================================================================================================================
*/
Static Function MFIN13Compensar(nRecnoNF,nRecnoDCT)
Local lContabiliza:= .F.
Local lAglutina   := .F.
Local lDigita     := .F.
Local aRecNF      := { nRecnoNF  } //NF
Local aRecSE1     := { nRecnoDCT } //DCT

BEGIN TRANSACTION

  If nRecnoNF > 0 .And. nRecnoDCT > 0
    If !MaIntBxCR(3,aRecNF,,aRecSE1,,{lContabiliza,lAglutina,lDigita,.F.,.F.,.F.},,,,,Date() )
	   //DisarmTransaction()
	   _cErro:="Erro: Não foi possível fazer a compensação do titulo "+SE1->E1_NUM 
    EndIf
 Else
    _cErro:="Erro: Não foi possível fazer a compensação do titulo "+SE1->E1_NUM+" Registros invalido: ["+CVALTOCHAR(nRecnoNF)+"] ["+CVALTOCHAR(nRecnoDCT)+"] "
 EndIf

END TRANSACTION

Return Empty(_cErro)

/*
===============================================================================================================================
Programa--------: MFIN16Tela()
Autor-----------: Alex Walaluer
Data da Criacao-: 03/06/2019
Descrição-------: Tela detalhe
Parametros------: Nenhum
Retorno---------: .T.
===============================================================================================================================
*/
Static Function MFIN16Tela(cAliasWK)

Local aBotoes      :={}
Local aTB_Campos   :={}
Local bMarcaTodos  :={|| U_MFIN016R("INVERTEMARCACAO") , oMark:oBrowse:Refresh() }
Local aCpoBrowse   :={}
Local aCoors	   := FWGetDialogSize(oMainWnd)
Local oDlg,oMark,I
Local _cTitAux:="Compensacao de titulos DCT"
Local aCab:={};_aCols:={}

aAdd(aBotoes,{"RESPONSA",{|| U_MFIN016R("DESMARCARALL") , oMark:oBrowse:Refresh() },"Desmarca Todos","Desmarca Todos"})
aAdd(aBotoes,{"RESPONSA",{|| U_MFIN016R("MARCARALL") , oMark:oBrowse:Refresh() },"Marca Todos","Marca Todos"})
aAdd(aBotoes,{"RESPONSA",{|| U_MFIN016R("VISUALNF") } ,"Visualizar NF"  ,"Visualizar NF"})
aAdd(aBotoes,{"RESPONSA",{|| U_MFIN016R("VISUALDCT")} ,"Visualizar DCT","Visualizar DCT"})
aAdd(aBotoes,{"BUDGET"  ,{|| MFIN16Legenda() } ,"Legenda"     ,"Legenda"})
aAdd(aBotoes,{"Exp. Excel"	, {|| DlgToExcel( { { "ARRAY" , _cTitAux , aCab , _aCols } } ) }, "Exportação de Dados para Excel"		, "Exp. Excel"		} )
aAdd(aBotoes,{"Exp. Arquivo", {|| U_ITGERARQ( _cTitAux , aCab , _aCols ) }					, "Exportação de Dados para Arquivo"	, "Exp. Arquivo"	} )

DBSelectArea(cAliasWK)

aAdd( aCpoBrowse , { "Filial"	 	,{|| (cAliasWK)->FILIAL + If(!Empty((cAliasWK)->FILIAL)," - "+LEFT(FWFilialName(cEmpAnt,(cAliasWK)->FILIAL,1),25),Space(25)) },"@!" } )
aAdd( aCpoBrowse , { "Titulo"		,{|| (cAliasWK)->TITU  }	, "@!"} )
aAdd( aCpoBrowse , { "Tipo NF"      ,{|| (cAliasWK)->E1_TIPONF }, AVSX3("E1_TIPO "   ,6)})
aAdd( aCpoBrowse , { "Tipo DCT "    ,{|| (cAliasWK)->E1_TIPO   }, AVSX3("E1_TIPO "   ,6)})
aAdd( aCpoBrowse , { "Prefixo NF"   ,{|| (cAliasWK)->E1_PREFINF}, AVSX3("E1_PREFIXO ",6)})
aAdd( aCpoBrowse , { "Prefixo DCT"  ,{|| (cAliasWK)->E1_PREFIXO}, AVSX3("E1_PREFIXO ",6)})
aAdd( aCpoBrowse , { "Parcela NF"	,{|| (cAliasWK)->WKPARCELA }, "@!"} )
aAdd( aCpoBrowse , { "Parcela DCT"	,{|| (cAliasWK)->WKPARCDCT }, "@!"} )
aAdd( aCpoBrowse , { "Cliente"		,{|| (cAliasWK)->CLIENTE }  , "@!" } )
aAdd( aCpoBrowse , { "Loja NF"		,{|| (cAliasWK)->LOJANF } 	, "@!"  } )
aAdd( aCpoBrowse , { "Loja DCT"		,{|| (cAliasWK)->LOJA } 	, "@!"  } )
aAdd( aCpoBrowse , { "Saldo NF"     ,{|| (cAliasWK)->SALDONF }	, "@E 999,999,999.99" } )
aAdd( aCpoBrowse , { "Saldo DCT"    ,{|| (cAliasWK)->SALDO }	, "@E 999,999,999.99" } )
aAdd( aCpoBrowse , { "Observação"	,{|| (cAliasWK)->ERRO  }	, ""} )
aAdd( aCpoBrowse , { "Registro NF"  ,{|| (cAliasWK)->REGSENF }	, "@E 999,999,999"} )
aAdd( aCpoBrowse , { "Registro DCT" ,{|| (cAliasWK)->REGSEDCT } , "@E 999,999,999"} )

aAdd(aTB_Campos,{"MARCA",,"",})
For I := 1 TO Len(aCpoBrowse)
    aAdd(aTB_Campos,{aCpoBrowse[I,2],,aCpoBrowse[I,1],aCpoBrowse[I,3]})
Next

//Botões de Exportar ***************************
aAdd(aCab,"Status" )
For I := 2 TO Len(aTB_Campos)
    aAdd(aCab,AllTrim(aTB_Campos[ I,3 ]) )
Next
(cAliasWK)->(DBGoTop())
While (cAliasWK)->(!Eof())
   _aColuna:={}
   aAdd(_aColuna, (cAliasWK)->WKSTATUS )
   aAdd(_aColuna, (cAliasWK)->FILIAL + If(!Empty((cAliasWK)->FILIAL)," - "+AllTrim(FWFilialName(cEmpAnt,(cAliasWK)->FILIAL,1)),"") )
   aAdd(_aColuna, "'"+(cAliasWK)->TITU  )
   For I := 4 TO Len(aTB_Campos)
       If ValType(aTB_Campos[ I,1 ]) = "C"
          _xConteudo:=cAliasWK+"->"+AllTrim(aTB_Campos[ I,1 ])
          _xConteudo:=&(_xConteudo)
          aAdd(_aColuna,_xConteudo )
       Else
          _xConteudo:=EVAL(aTB_Campos[ I,1 ])
          aAdd(_aColuna,_xConteudo )
       EndIf   
   Next
   aAdd(_aCols, _aColuna )
   (cAliasWK)->(DBSkip())    
EndDo
//Botões de Exportar ***************************

While .T.
   nOpca:=0

   oMainWnd:ReadClientCoords()//So precisa declarar uma fez para o Programa todo
   DEFINE MSDIALOG oDlg TITLE _cTitAux From aCoors[1],aCoors[2] TO aCoors[3],aCoors[4] OF oMainWnd PIXEL

    (cAliasWK)->(DBGoTop())
    oMark:=MSSELECT():New(cAliasWK,"MARCA","WKSTATUS <> 'A'",aTB_Campos,.F.,@cMarca,{21,1,(oDlg:nClientHeight-6)/2,(oDlg:nClientWidth-4)/2})

  	oMark:bAval                      := {|| U_MFIN016R("MARCAR"),oMark:oBrowse:Refresh() }
  	oMark:oBrowse:bAllMark           := bMarcaTodos
	oMark:oBrowse:lhasMark           := .T.
	oMark:oBrowse:lCanAllmark        := .T.

    oMark:oBrowse:aColumns[2]        := TCColumn():New()
    oMark:oBrowse:aColumns[2]:lBitmap:= .T.
    oMark:oBrowse:aColumns[2]:lNoLite:= .T.
    oMark:oBrowse:aColumns[2]:nWidth := 33
    oMark:oBrowse:aColumns[2]:bData  := {|| If((cAliasWK)->WKSTATUS = 'A', "BR_VERDE",If((cAliasWK)->WKSTATUS = 'E',"BR_PRETO",If((cAliasWK)->WKSTATUS = 'P', "BR_AZUL","BR_VERMELHO")))}

   ACTIVATE MSDIALOG oDlg ON INIT ( EnchoiceBar(oDlg, {|| (nOpca:=1,oDlg:End()) } , {|| (nOpca:=0,oDlg:End()) },,aBotoes) ,;
                                    oMark:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT ,;
                                    oMark:oBrowse:Refresh() )
   If nOpca = 1
      (cAliasWK)->(DBGoTop()) 
      nTotal:=0
      (cAliasWK)->( DBEval( {|| nTotal++ }, {|| !Empty((cAliasWK)->MARCA) } , {|| .T.} ) )
      If nTotal = 0
         U_ITMsg("Não existem registros marcados, marque pelo menos uma viagem válida para integrar!","Atenção",,1)
         Loop
      EndIf
      If U_ITMsg("Confirma a Compensação?" ,"Atenção","Serão conpensados "+AllTrim(Str(nTotal,10))+" titulos",3,2,2 ) 
         FWMsgRun( ,{|oproc| U_MFIN016B(oproc)},"Aguarde","Processando..." )
         Loop
      Else
         Loop
      EndIf
   ElseIf nOpca = 0 
      If U_ITMsg("Confirma o CANCELAMENTO?" ,"Atenção" ,"Todos os dados lidos seram perdidos: ", 3,2,2 )
         Return .F.
      Else
         Loop
      EndIf
   EndIf

   Exit

EndDo

Return .T.               

*--------------------------------------------------------------------------------------*
Static Function MFIN16Legenda()
*--------------------------------------------------------------------------------------*
Local aLegenda:={}
aAdd(aLegenda,{"ENABLE"    ,"Aceitos"    })
aAdd(aLegenda,{"DISABLE"   ,"Rejeitados" })
aAdd(aLegenda,{"BR_AZUL"   ,"Processados"})
aAdd(aLegenda,{"BR_PRETO"  ,"Analizar"   })
BrwLegenda("Legenda","Legenda",aLegenda)
Return .T.
