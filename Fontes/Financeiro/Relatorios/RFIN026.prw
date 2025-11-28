/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |06/05/2025| Chamado 50525. Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RFIN026
Autor-------------: Alex Wallauer
Data da Criacao---: 13/11/2023
Descrição---------: Chamado 45578 - Antonio. Relatório de CARTA DE CESSÃO, que o financeiro utilizará para o Broker.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RFIN026()

Local _nI        := 0
Local _aParRet   := {}
Local _aParAux   := {}
Local _bOK       := {|| If(MV_PAR03 >= MV_PAR02 ,.T.,(U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo",3),.F.) ) }
Local _lRet      := .F.

Private _cTitulo := "Relatório de CARTA DE CESSÃO"

MV_PAR01 := Space(200)
MV_PAR02 := Ctod("")
MV_PAR03 := Ctod("")
MV_PAR04 := Space(200)
MV_PAR05 := Space(050)

aAdd( _aParAux , { 1 , "Filiais"          , MV_PAR01, ""	   , ""	, "LSTFIL"	, "" , 100, .F. } )
aAdd( _aParAux , { 1 , "Data de"          , MV_PAR02, "@D"	, ""  , ""	      , "" , 050, .T. } )
aAdd( _aParAux , { 1 , "Data ate"         , MV_PAR03, "@D"	, ""  , ""	      , "" , 050, .T. } )
aAdd( _aParAux , { 1 , "Selecione a Pasta", MV_PAR04, "@!"	, ""  , "DIRAGR"  , "" , 100, .T. } )
aAdd( _aParAux , { 1 , "Nome do Arquivo"  , MV_PAR05, "@!"	, ""  , "      "  , "" , 100, .T. } )

For _nI := 1 To Len( _aParAux )
      aAdd( _aParRet , _aParAux[_nI][03] )
Next _nI

While .T. 
    //aParametros, cTitle            , @aRet    ,[bOk]  , [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
   If !ParamBox( _aParAux , _cTitulo , @_aParRet,  _bOK , /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
      Exit
   Else
      _cTimeIni  := Time()
      FWMsgRun( ,{|oProc|  _lRet := RFIN026PR(oProc) } , "Hora Inicial: "+_cTimeIni+" Pesquisando títulos... " )   
   EndIf
EndDo

Return _lRet

/*
===============================================================================================================================
Programa----------: RFIN026PR
Autor-------------: Alex Wallauer
Data da Criacao---: 13/11/2023
Descrição---------: Processamento da rotina
Parametros--------: oProc = objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN026PR(oProc)

Local _aCab   := {}
Local _aSizes := {}
Local _cMsgTop:= ""  
Local _lRet   :=.F.

Private _cTot

_aTit := RFIN026QRY(oProc)

_cMsgTop:=" Total de Titulos: "+_cTot+" / Hora inical: "+_cTimeIni+", Hora Final: "+Time()

If Len(_aTit) = 0
   U_ITMsg( "De acordo com os parâmetros imputados não foi encontrado registro no periodo!" , "Atenção!",,2 )
Else
   _aCab := {}
   _aSizes:=NIL
   aAdd(_aCab,"")
   aAdd(_aCab,"Filial")
   aAdd(_aCab,"Nome da Cessionária")
   aAdd(_aCab,"Endereço da Cessionária")
   aAdd(_aCab,"Bairro da Cessionária")
   aAdd(_aCab,"Cidade da Cessionária")
   aAdd(_aCab,"Estado da Cessionária")
   aAdd(_aCab,"CEP da Cessionária")
   aAdd(_aCab,"CNPJ da Cessionária")
   aAdd(_aCab,"Nome do Cliente")
   aAdd(_aCab,"Dt de Pagto")
   aAdd(_aCab,"Vecto Original")
   aAdd(_aCab,"R$ Original")
   aAdd(_aCab,"Vlr Atualizado")
   aAdd(_aCab,"Titulo NF") ; nPosTit:=Len(_aCab)
   aAdd(_aCab,"Parcela")   ; nPosPar:=Len(_aCab)
   aAdd(_aCab,"Observações")
   While .T.            

      _aTit	:= aSort( _aTit  ,,, {|x, y| x[2]+x[3]+x[nPosTit]+x[nPosPar] < y[2]+y[3]+y[nPosTit]+y[nPosPar] } )//Por Garantia caso o usuario mude a ordem na tela

      _lRet := U_ITListBox(_cTitulo, _aCab, @_aTit, .T., 2, @_cMsgTop, .F., _aSizes ,,,,,,  ,,,,,  )
      If _lRet
         If U_ITMsg("Confirma geracao das CARTAS ?",'Atenção!',,3,2,3,,"CONFIRMA","Voltar")
            FWORD_IMP(oProc)
         EndIf
         Loop
      EndIf
      Exit
   EndDo

EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: RFIN026QRY
Autor-------------: Alex Wallauer
Data da Criacao---: 13/11/2023
Descrição---------: Executa Busca de Títulos
Parametros--------: Nenhum
Retorno-----------: oProc = Status de Processamento
===============================================================================================================================
*/
Static Function RFIN026QRY(oProc)

Local _cFiltro:= "% "
Local _aTit   := {}
Local _cAlias := ""

If !Empty(MV_PAR01)
	_cFiltro += " AND E1_FILIAL IN " + FormatIn(AllTrim(MV_PAR01),";") 
EndIf

_cFiltro += " AND E5_DATA BETWEEN '" + DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "' "

_cFiltro += " %"
	
_cAlias:= GetNextAlias()
If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

BeginSql Alias _cAlias
     // MARCACAO       //01
      SELECT E1_FILIAL //02
          ,  A1_NOME   //03
          ,  A1_END,A1_I_NUM,A1_COMPLEM,A1_I_END//04
          ,  A1_BAIRRO //05
          ,  A1_MUN    //06
          ,  A1_EST    //07
          ,  A1_CEP    //08
          ,  A1_CGC    //09
          ,  E5_BENEF  //10
          ,  E1_EMISSAO//11
          ,  E5_VENCTO //12
          ,  E5_VALOR  //13
          ,  E1_VALLIQ //14
          ,  E5_NUMERO //15
          ,  E5_PARCELA//16          
         FROM %Table:SE1% SE1
        INNER JOIN %Table:SE5% SE5 ON SE5.D_E_L_E_T_ =' ' AND E1_FILIAL  = E5_FILIAL AND E1_NUMLIQ  = E5_DOCUMEN 
        INNER JOIN %Table:SA1% SA1 ON SA1.D_E_L_E_T_ =' ' AND E1_CLIENTE = A1_COD    AND E1_LOJA    = A1_LOJA
        INNER JOIN %Table:SA3% SA3 ON SA3.D_E_L_E_T_ =' ' AND A1_CGC     = A3_CGC    AND A3_I_VBROK ='B'
        WHERE SE1.D_E_L_E_T_ =' ' AND E1_NUMLIQ    <> ' ' AND E1_PREFIXO = 'R' %Exp:_cFiltro%
        ORDER BY E1_FILIAL, A1_NOME , E5_NUMERO , E5_PARCELA
EndSql

_nTot:=nConta:=0
COUNT TO _nTot
_cTot:=AllTrim(Str(_nTot))

(_cAlias)->(DBGoTop())

While (_cAlias)->(!Eof())
   nConta++
   oProc:cCaption := ('Lendo: '+AllTrim(Str(nConta))+" de "+_cTot )
   ProcessMessages()
   
   _cA1Endereco := AllTrim((_cAlias)->A1_END)
   If !(AllTrim((_cAlias)->A1_I_NUM) $ (_cAlias)->A1_END)
   	If !Empty((_cAlias)->A1_I_END) .And. Empty((_cAlias)->A1_I_NUM) .And. Empty((_cAlias)->A1_COMPLEM)
   		_cA1Endereco := AllTrim((_cAlias)->A1_I_END)
   	ElseIf !Empty((_cAlias)->A1_I_END) .And. !Empty((_cAlias)->A1_I_NUM) .And. Empty((_cAlias)->A1_COMPLEM)
   		_cA1Endereco := AllTrim((_cAlias)->A1_I_END) + ", " + AllTrim((_cAlias)->A1_I_NUM)
   	ElseIf !Empty((_cAlias)->A1_I_END) .And. !Empty((_cAlias)->A1_I_NUM) .And. !Empty((_cAlias)->A1_COMPLEM)
   		_cA1Endereco := AllTrim((_cAlias)->A1_I_END) + ", " + AllTrim((_cAlias)->A1_I_NUM) + " " + AllTrim((_cAlias)->A1_COMPLEM)
   	EndIf
   EndIf

   _aItens:={}
   aAdd(_aItens,.T.                        )//01
   aAdd(_aItens,(_cAlias)->E1_FILIAL       )//02
   aAdd(_aItens,(_cAlias)->A1_NOME         )//03
   aAdd(_aItens,_cA1Endereco               )//04
   aAdd(_aItens,(_cAlias)->A1_BAIRRO       )//05
   aAdd(_aItens,(_cAlias)->A1_MUN          )//06
   aAdd(_aItens,(_cAlias)->A1_EST          )//07
   aAdd(_aItens,TRANS((_cAlias)->A1_CEP,"!@R #####-###"))//08
   aAdd(_aItens,TRANS((_cAlias)->A1_CGC,"@R ##.###.###/####-##"))//09
   aAdd(_aItens,(_cAlias)->E5_BENEF        )//10
   aAdd(_aItens,SToD((_cAlias)->E1_EMISSAO))//11
   aAdd(_aItens,SToD((_cAlias)->E5_VENCTO ))//12
   aAdd(_aItens,(_cAlias)->E5_VALOR        )//13
   aAdd(_aItens,(_cAlias)->E1_VALLIQ       )//14
   aAdd(_aItens,(_cAlias)->E5_NUMERO       )//15
   aAdd(_aItens,(_cAlias)->E5_PARCELA      )//16
   aAdd(_aItens,Space(300)                 )//17

   aAdd(_aTit,_aItens)
   
   (_cAlias)->(DBSkip())

EndDo

(_cAlias)->(DBCloseArea())

Return _aTit

/*
===============================================================================================================================
Programa----------: fWord_Imp()
Autor-------------: Alex Wallauer
Data da Criacao---: 13/11/2023
Descrição---------: Executa geração do documento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function fWord_Imp(oProc)

Local oWord			:= NIL
Local aCampos		:= {}
Local T        	:= 0
Local cNomeDOT	   := "cbroker.dot"
Local cPatSaida   := AllTrim( MV_PAR04 )             // Pat de destino selcionado pelo usuario
Local cPatIncial 	:= cPatSaida+cNomeDOT              // 1o lugar a olhar
Local cArqWorDOT	:= "\data\Italac\dots\cbroker.dot" // 2o lugar a olhar           
Local cArqLocDOT	:= GetTempPath()+"cbroker.dot"     // 3o lugar a olhar        
Local cArqTstDOT	:= "\data\Alex\cbroker.dot"        // 4o lugar a olhar    
Local lRet			:= .T.
Local _cMask1     := PesqPict( "SE5" , "E5_VALOR" )
Local _cMask2     := PesqPict( "SE1" , "E1_VALLIQ") 
oProc:cCaption := ("Lendo cbroker.dot..........." )
// Checa o SO do Remote (1=Windows, 2=Linux)
If GetRemoteType() == 2
   U_ITMsg("Integracao Word funciona somente com Windows !!!", "Atencao !",,1)
	Return .F.
EndIf
If Right(cPatSaida,1) <> "\"
   cPatSaida := cPatSaida + "\"
EndIf
cPatIncial    := cPatSaida+cNomeDOT// <== MV_PAR04 ==> 1o lugar a olhar
If File(cPatIncial)//cPatSaida+"cbroker.dot"
   cArqWorDOT:=cPatIncial// 1o lugar a olhar
EndIf
If !File(cArqWorDOT)//"\data\Italac\dots\cbroker.dot"// 2o lugar a olhar
   cArqWorDOT:=cArqLocDOT
EndIf
If !File(cArqWorDOT)//GetTempPath()+"cbroker.dot"    // 3o lugar a olhar
   cArqWorDOT:=cArqTstDOT
EndIf
If !File(cArqWorDOT)//"\data\Alex\cbroker.dot" // 4o lugar a olhar  
	U_ITMsg("Modelo do Word não encontrado "+cArqWorDOT, "Atencao !",,1)
	Return .F.
EndIf

If cArqWorDOT <> cPatIncial 
   If CpyS2T(@cArqWorDOT,@cPatSaida,.F.)//COPIA PARA O DIRETORIO ESCOLHIDO
      cArqWorDOT:=cPatIncial
   Else
	   U_ITMsg("Não conseguiu copiar "+cArqWorDOT+" para "+cPatSaida, "Atencao !",,1)
      Return .F.
   EndIf
EndIf

cPatSaida:= cPatSaida+AllTrim(MV_PAR05)// <== MV_PAR04 + MV_PAR05

_aTit:=aSort(_aTit,,,{|x,y| x[2]+x[3]+x[nPosTit]+x[nPosPar] < y[2]+y[3]+y[nPosTit]+y[nPosPar] } )//POR GARANTIA CASO O USUARIO MUDE A ORDEM NA TELA

_nQtde:=0
_cChaveQuebra := " "
_nTot:=nConta:=0
_nTot:=Len(_aTit)
_cTot:=AllTrim(Str(_nTot))

For T := 1 TO Len(_aTit)

    oProc:cCaption := ('Lendo marcados: '+AllTrim(Str(nConta))+" de "+_cTot+" - Buscando dados..........." )
    ProcessMessages()

      If !_aTit[T,1]
          Loop
      EndIf

		// Carregando Informacoes da Empresa
		If _aTit[T,2]+_aTit[T,3] # _cChaveQuebra
         aInfo := FWSM0Util():GetSM0Data("01",_aTit[T,2],;
                  {"M0_NOMECOM",;
                   "M0_CGC"    ,;
                   "M0_ENDENT" ,;
                   "M0_BAIRENT",;
                   "M0_CIDENT" ,;
                   "M0_ESTENT" ,;
                   "M0_CEPENT" })

         If Empty(aInfo)
				_aTit[T,Len(_aTit[T])]:="Não foi possível carregar as informações da Filial: "+_aTit[T,2]
				Loop
			EndIf
			// Atualiza a Variavel _cChaveQuebra
			_cChaveQuebra := _aTit[T,2]+_aTit[T,3]

         _nQtde++
         cArqAux:=cPatSaida+"_"+StrZero(_nQtde,4)
         While File(cArqAux+".docx") .Or. File(cArqAux+".doc")
            _nQtde++
            cArqAux:=cPatSaida+"_"+StrZero(_nQtde,4)
         EndDo

         oProc:cCaption := ('Lendo marcados: '+AllTrim(Str(nConta))+" de "+_cTot+" - Criando carta "+StrZero(_nQtde,4)+"...." )
         ProcessMessages()
         // Inicializa o Ole com o MS-Word
         oWord	:= OLE_CreateLink()
         OLE_NewFile( oWord , cArqWorDOT )

		EndIf

  		// Carrega Campos Disponiveis para Edicao
		aCampos := fCpos_Word(T)

		// Ajustando as Variaveis do Documento
		Aeval(aCampos,{|x| OLE_SetDocumentVar( oWord ,x[1],  Transform( x[2] , x[3] ) ) })

      //Sera utilizado na macro do documento para execucao do For Next
      //Montagem das variaveis dos itens. No documento word estas variaveis serao criadas //dinamicamente da seguinte forma:
      //tit_cliente1, tit_cliente2 ... tit_cliente6
      nValorTotal:=0
      nTotFORMacro:=1
      nLinha:=1
		While T <= Len(_aTit) .And. _aTit[T,2]+_aTit[T,3] == _cChaveQuebra 
         If !_aTit[T,1]
            T++
            Loop
         EndIf
         OLE_SetDocumentVar(oWord,"tit_cliente"   +AllTrim(Str(nLinha)),_aTit[T,10])
         OLE_SetDocumentVar(oWord,"tit_dt_pagto"  +AllTrim(Str(nLinha)),_aTit[T,11])
         OLE_SetDocumentVar(oWord,"tit_vencimento"+AllTrim(Str(nLinha)),_aTit[T,12])
         OLE_SetDocumentVar(oWord,"tit_original"  +AllTrim(Str(nLinha)),TRANSFORM( _aTit[T,13] , _cMask1))
         OLE_SetDocumentVar(oWord,"tit_atualizado"+AllTrim(Str(nLinha)),TRANSFORM( _aTit[T,14] , _cMask2))
         If !Empty(_aTit[T,16])
            OLE_SetDocumentVar(oWord,"tit_titulo" +AllTrim(Str(nLinha)),_aTit[T,15]+"-"+AllTrim(_aTit[T,16]))
         Else
            OLE_SetDocumentVar(oWord,"tit_titulo" +AllTrim(Str(nLinha)),_aTit[T,15])
         EndIf 
         _aTit[T,Len(_aTit[T])]:="Gerado com Sucesso na Carta: "+cArqAux+".docx"
         nValorTotal+=_aTit[T,14]
         nTotFORMacro++
         nLinha++
         nConta++
         T++
      EndDo
      If T <> Len(_aTit)
         T--
      EndIf
      If T > Len(_aTit)
         T:=Len(_aTit)
      EndIf

      //BATE O TOTAL NA ULTIMA LINHA
      OLE_SetDocumentVar(oWord,"TIT_CLIENTE"   +AllTrim(Str(nLinha))," ")
      OLE_SetDocumentVar(oWord,"TIT_DT_PAGTO"  +AllTrim(Str(nLinha))," ")
      OLE_SetDocumentVar(oWord,"TIT_VENCIMENTO"+AllTrim(Str(nLinha))," ")
      OLE_SetDocumentVar(oWord,"TIT_ORIGINAL"  +AllTrim(Str(nLinha))," ")
      OLE_SetDocumentVar(oWord,"TIT_ATUALIZADO"+AllTrim(Str(nLinha)),Transform(nValorTotal,"@E 999,999,999,999.99"))
      OLE_SetDocumentVar(oWord,"TIT_TITULO"    +AllTrim(Str(nLinha))," ")
      OLE_SetDocumentVar(oWord,'TIT_NROITENS'  ,nTotFORMacro)//A macro usa esse total para fazer o For dela 
      OLE_SetDocumentVar(oWord,'TIT_VALORTOTAL',AllTrim(Transform(nValorTotal,"@E 999,999,999,999.99")))
      
      //Extenso(1,2,3,4,5,6,7)
      //1 - nValor   = Valor numerico no qual a funcao retornara o seu valor numerico
      //2 - lQuantid = Valor logico que especifica se o retorno da Extenso sera para quantidade ou para valores. O default e ".F.".
      //3 - nMoeda   = Identifica em que moeda se dara o retorno.
      //4 - cPrefixo = Prefixo alternativo. Caso especificado, prefixa o retorno do extenso. Fazendo com que a unidade monetaria nao seja impressa.
      //5 - cIdioma  = Especifica em qual idioma devera ser retornado o valor do extenso.(1=Port.2=Espa.3=Ingl)
      //6 - lCent    = Especifica se a funcao devera retornar os centavos. O default e .T.
      //7 - lFrac    = Especifica se os centavos deverao ser retornados em modo fracionado(Somente funcionara com o idioma Ingles)       
      _cVlrExtenso:=LOWER(AllTrim(Extenso(nValorTotal)))
      _cVlrExtenso:=Upper( LEFT( _cVlrExtenso, 1 ) )+SubStr( _cVlrExtenso, 2 )
      OLE_SetDocumentVar(oWord, 'TIT_VALOR_EXTENSO',_cVlrExtenso)
		//EndIf
      
      dDataExtenso := cValToChar(Day(dDataBase))
      dDataExtenso += " de "
      dDataExtenso += LOWER(MesExtenso(dDataBase))
      dDataExtenso += " de "
      dDataExtenso += cValToChar(Year(dDataBase))
      OLE_SetDocumentVar(oWord, 'TIT_DATA_EXTENSO',AllTrim(dDataExtenso))

      oProc:cCaption := ('Lendo marcados: '+AllTrim(Str(nConta))+" de "+_cTot+" - Atualizando Variaveis.." )
      ProcessMessages()
		// Atualiza as Variaveis
		OLE_SetProperty( oWord, '208', .F. )
		OLE_UpDateFields( oWord )

      oProc:cCaption := ('Lendo marcados: '+AllTrim(Str(nConta))+" de "+_cTot+" - Executando Macro......." )
      ProcessMessages()
      OLE_ExecuteMacro(oWord,"tabintens")

      oProc:cCaption := ('Lendo marcados: '+AllTrim(Str(nConta))+" de "+_cTot+" - Salvando Carta "+StrZero(_nQtde,4)+"....")
      ProcessMessages()
		OLE_SaveAsFile( oWord, cArqAux )
	
      // Encerrando o Link com o Documento
	   OLE_CloseLink( oWord )

Next

Return( lRet )

/*
===============================================================================================================================
Programa----------: fWord_Imp()
Autor-------------: Alex Wallauer
Data da Criacao---: 13/11/2023
Descrição---------: Executa geração do documento
                    aExp[x,1]-Variavel Para utilizacao no Word (Tam Max. 30)  
                    aExp[x,2]-Conteudo do Campo                (Tam Max. 49)  
                    aExp[x,3]-Campo para Pesquisa da Picture no X3 ou Picture 
                    aExp[x,4]-Descricao da Variaval                           
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function fCpos_Word(T)

Local aExp			:= {}

//DADSOS DA CAPA
aAdd( aExp, {'TIT_NOME_EMPRESA',aInfo[1,2],"@!"						  ,""})
aAdd( aExp, {'TIT_CNPJ_EMPRESA',aInfo[2,2],"@R ##.###.###/####-##",""})
aAdd( aExp, {'TIT_END_EMPRESA' ,aInfo[3,2],"@!"						  ,""})
aAdd( aExp, {'TIT_BAI_EMPRESA' ,aInfo[4,2],"@!" 						  ,""})
aAdd( aExp, {'TIT_CID_EMPRESA' ,aInfo[5,2],"@!"						  ,""})
aAdd( aExp, {'TIT_EST_EMPRESA' ,aInfo[6,2],"@!"						  ,""})
aAdd( aExp, {'TIT_CEP_EMPRESA' ,aInfo[7,2],"!@R #####-###"        ,""})

aAdd( aExp, {'TIT_NOME'		  ,_aTit[T,03],"",""})
aAdd( aExp, {'TIT_ENDERECO'  ,_aTit[T,04],"",""})
aAdd( aExp, {'TIT_BAIRRO'    ,_aTit[T,05],"",""})
aAdd( aExp, {'TIT_MUNICIPIO' ,_aTit[T,06],"",""})
aAdd( aExp, {'TIT_ESTADO'    ,_aTit[T,07],"",""})
aAdd( aExp, {'TIT_CEP'       ,_aTit[T,08],"",""})
aAdd( aExp, {'TIT_CNPJ'      ,_aTit[T,09],"",""})
	
Return( aExp )
