/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 19/03/2017 | Chamado 24190 - Incluida chamada a atualização RDC do cliente.
 Josué Danich     | 16/04/2017 | Chamado 24518 - Ajuste de detectção de excel/libreoffice.        
 Jerry            | 10/03/2020 | Chamado 32247 - Ajuste da validação do Fim de Arquivo após converter para CSV.
 Jonathan         | 26/05/2020 | Chamado 32110 - Ajuste para novo layout de importação.
 Alex Wallauer    | 03/02/2021 | Chamado 35510 - Ajustes na validacao no teste do cabeçalho.
 Alex Wallauer    | 10/02/2022 | Chamado 39164 - Ajustes na validacao do teste quantidade de colunas/inclusao de legenda.
 Igor Melgaco     | 31/07/2024 | Chamado 48054 - Retirada do SA1.A1_MSBLQL = '2' 
=============================================================================================================================== 
Analista     - Programador  - Inicio   - Envio    - Chamado - Motivo da Alteração
===============================================================================================================================
Jerry        - Julio Paz    - 24/01/25 - 13/05/25 - 48792   - Realização de ajustes na gravação da data e hora na importação Chep e criação de uma rotina para visualizar o resultado da importação.
Alex         - Igor Melgaço - 02/05/25 - 13/05/25 - 50525   - Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
Jerry        - Julio Paz    - 07/05/25 - 13/05/25 - 48792   - Inclusão do campo ZGM_STATUS na listagem de pedidos processados.
===============================================================================================================================
*/
#Include "rwmake.ch"
#Include "APWEBSRV.CH"
#Include "TOTVS.ch"
#Include "TBICONN.CH"   
#Include "FWMVCDef.Ch"
#Include "topconn.Ch" 

/*
===============================================================================================================================
Programa----------: MOMS036
Autor-------------: Josué Danich Prestes
Data da Criacao---: 28/02/2018
===============================================================================================================================
Descrição---------: Importação de arquivo de clientes CHEP - Chamado 23911
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS036()


Local 	_cAlias		:= "ZGM"
Private cCadastro	:= "Importação arquivo Chep"
Private aRotina		:= {}                


aAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
aAdd(aRotina,{"Importar"	,"FWMsgRun( ,{|oproc| U_MOMS036P(oproc) } , 'Processando...' , 'Iniciando o processamento...' )",0,2})

	
DBSelectArea(_cAlias)
DBSetOrder(1)
mBrowse(6,1,22,75,_cAlias)

Return

/*
===============================================================================================================================
Programa----------: MOMS036P
Autor-------------: Josué Danich Prestes
Data da Criacao---: 28/02/2018
===============================================================================================================================
Descrição---------: Processamento de Importação de arquivo de clientes CHEP
===============================================================================================================================
Parametros--------: oproc2 - objeto da barra de processamento
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS036P(oproc2)

Local _aParaux  := {}
Local _aParRet  := {}
Local _aDados   := {}
Local _aMuda    := {}
Local _cCodUsr	:= RetCodUsr()
Local nI        := 0 , _nip
Local _dDataImp 
Local _cHoraImp
Local _cQry
Local _cAliasQry := GetNextAlias() 
Local _nTotRegs  := 0
Local _aDadosRel := {}
Local _aLinha := {}
Local _cPathTemp := GetTempPath()

aAdd( _aParAux , { 1 , "Selecione arquivo:"		, Space(150)	, "@!"		, ""	, "DIR"		, "" , 100 , .F. } ) 	//| 01 |

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next nI
          //aParametros, cTitle            , @aRet     ,[bOk]  , [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
If !ParamBox( _aParAux , "Importação Chep" , @_aParRet ,/*bOK*/, /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )

	U_ITMsg( "Operação cancelada pelo usuário!" , "Atenção!",,1 )
	Return
	
EndIf

oproc2:cCaption := ( "Abrindo arquivo..." )
ferase(_cPathTemp+"csvtemp.csv")
ferase(_cPathTemp+"xlstemp.xls")

//Se For arquivo excel vai converte primeiro para csv para poder trabalhar
If Upper(right(AllTrim(MV_PAR01),3)) == "XLS" .Or. Upper(right(AllTrim(MV_PAR01),4)) == "XLSX" 
	
     If ValType(oproc2) = "O"

      	oproc2:cCaption := ("Detectado arquivo XLS convertendo para CSV...")
   		ProcessMessages()
 
    EndIf
    
    _copyfile(MV_PAR01,_cPathTemp+"xlstemp.xls")
		
	
	//If !file("c:\Program Files\LibreOffice\program\scalc.exe")  //Não tem libreoffice tenta com excel
	
		
		If ValType(oproc2) = "O"

      	  oproc2:cCaption := ("Usando Excel para converter para CSV...")
   		  ProcessMessages()
 
        EndIf
		
		_nHandle := FCreate(_cPathTemp+"converzz.vbs")
		FWrite(_nHandle, "Dim oExcel" + CHR(13))
		FWrite(_nHandle, 'Set oExcel = CreateObject("Excel.Application")'+ CHR(13))
		FWrite(_nHandle, "Dim oBook"+ CHR(13))
		FWrite(_nHandle, "Set oBook = oExcel.Workbooks.Open(Wscript.Arguments.Item(0))"+ CHR(13))
		FWrite(_nHandle, 'oBook.Sheets(1).Range("A1:A99999").NumberFormat = "################"'+ CHR(13))
		FWrite(_nHandle, "oBook.SaveAs WScript.Arguments.Item(1), 6"+ CHR(13))
		FWrite(_nHandle, "oBook.Close False"+ CHR(13))
		FWrite(_nHandle, "oExcel.Quit"+ CHR(13))
		FClose(_nHandle)

		ShellExecute("open", _cPathTemp+"converzz.vbs", _cPathTemp+"xlstemp.xls " + _cPathTemp + "csvtemp.csv", "", 0)
	
	/*Else //Tem Libreoffice
	
		If ValType(oproc2) = "O"

      	  oproc2:cCaption := ("Usando Libreoffice  para converter para CSV...")
   		  ProcessMessages()
 
        EndIf
		
		_llibof := .T.
		//_copyfile("c:\smartclient\xlstemp.xls","c:\smartclient\csvtemp.xls")
		//ShellExecute("open", "c:\Program Files\LibreOffice\program\scalc.exe", "--headless --convert-to csv  c:\smartclient\csvtemp.xls", "c:\smartclient", 0)
		
				
	EndIf*/
		
	//tempo de espera para garantir que arquivo foi finalizado
	Sleep(9000) 

	If FT_FUSE(_cPathTemp+"csvtemp.csv") == -1
	
		U_ITMsg("Falha ao converter o arquivo excel","Erro",,1)
		
		Return
		
	EndIf 


ElseIf Upper(right(AllTrim(MV_PAR01),3)) == "CSV"

	If FT_FUSE(MV_PAR01) == -1
	
		U_ITMsg("Falha ao abrir arquivo csv","Erro",,1)
		
		Return
		
	EndIf 

Else

	U_ITMsg("Arquivo selecionado precisa ser XLS ou CSV","Atenção",,1)
	
	Return


EndIf
	
_nReg:= (FT_FLASTREC()-1)
			
//Detecta layout de client
FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
_cDados := FT_FREADLN()

If ",,,,,,"  $ AllTrim(_cDados)
	FT_FSKIP()
	_cDados := FT_FREADLN()
EndIf 

//If AllTrim(_cDados) != ",Partner,RAZÃO SOCIAL,ENDEREÇO,CIDADE,ESTADO,CEP,CNPJ,STATUS,Service Type,Date Joined Pool,AFF,New AFF?,Contract?,ABPA Channel"
If !"Partner,RAZÃO SOCIAL,ENDEREÇO,CIDADE,ESTADO,CEP,CNPJ" $ _cDados//,STATUS,Service Type,Date Joined Pool,AFF,New AFF?,Contract?,ABPA Channel

	U_ITMsg("Arquivo não está no layout da Chep","Atenção","Titulos corretos: Partner, RAZÃO SOCIAL, ENDEREÇO, CIDADE, ESTADO, CEP, CNPJ",1)//,STATUS,Service Type,Date Joined Pool,AFF,New AFF?,Contract?,ABPA Channel
	
Else

	oproc2:cCaption := ("Processando arquivo CSV...")
    ProcessMessages()

    _nI := 1
	SA1->(DBSetOrder(3))
	FT_FSKIP()//pula o cabecalho
	Do  While !(FT_FEOF())

		oproc2:cCaption := ("Processando arquivo CSV, lendo registro: " + StrZero(_nI,6)+" de "+StrZero(_nReg,6) )
		ProcessMessages()
		
		_cDados := FT_FREADLN()
     
		If ",,,,,,,"  $ AllTrim(_cDados)     
		                                                  
			Exit
			
		EndIf
		                                             
		_nn := 1
		_ldentro := .F.
		_ctexto := ""
		
		
		//Retira aspas e virgulas que não sejam separadoras de campos
		While _nn <= Len (_cDados)
		
			If _ldentro
			
				If SubStr(_cDados,_nn,1) == '"'
			
					_ldentro := .F.
					
				ElseIf SubStr(_cDados,_nn,1) != ','
				
					_ctexto := _ctexto + SubStr(_cDados,_nn,1)
					
				EndIf
			
			
			Else
			
				If SubStr(_cDados,_nn,1) == '"'
			
					_ldentro := .T.
					
				Else
				
					_ctexto := _ctexto + SubStr(_cDados,_nn,1)
					
				EndIf
				
			EndIf
			
			_nn++

		EndDo
		
		_alinha := StrTokArr(_ctexto,",")
		
		//Localiza clientes não chep existentes na lista para ativar
		If Len(_alinha) >= 7 .And. aScan(_aDados,{|_vAux|_vAux[7]== StrZero(Val(AllTrim(_alinha[7])),14)}) == 0
			aAdd(_aDados, _alinha )
					
			//SA1->(DBSetOrder(3))
			If SA1->(DBSeek(xFilial("SA1")+PadL(StrTran(StrTran(StrTran(AllTrim(_alinha[7]),".",""),"/",""),"-",""),14,"0"))) 
			   If AllTrim(SA1->A1_I_CCHEP) != AllTrim(_alinha[1]) 
			      If aScan(_aMuda,{|_vAux|_vAux[2]== AllTrim(SA1->A1_CGC)}) == 0
			 	     aAdd(_aMuda,{.T.,AllTrim(SA1->A1_CGC),SA1->A1_COD,SA1->A1_LOJA,SubStr(AllTrim(SA1->A1_NOME),1,20),SubStr(AllTrim(SA1->A1_NREDUZ),1,15),"Atualizar como cliente CHEP", AllTrim(_alinha[1]) })
				  Else
			 	     aAdd(_aMuda,{.F.,AllTrim(SA1->A1_CGC),SA1->A1_COD,SA1->A1_LOJA,SubStr(AllTrim(SA1->A1_NOME),1,20),SubStr(AllTrim(SA1->A1_NREDUZ),1,15),"-CNPJ repetido na planilha",""})
				  EndIf
			   Else 
		 	      aAdd(_aMuda,{.F.,AllTrim(SA1->A1_CGC),SA1->A1_COD,SA1->A1_LOJA,SubStr(AllTrim(SA1->A1_NOME),1,20),SubStr(AllTrim(SA1->A1_NREDUZ),1,15),"-Sem alteracao",""})
			   EndIf
			Else 	
			 	aAdd(_aMuda,{.F.,AllTrim(_alinha[7]),"","",_alinha[2],_alinha[3],"-CNPJ nao encontrado",""})
			EndIf
		
        ElseIf 	Len(_alinha) < 7

			//SA1->(DBSetOrder(3))
			SA1->(DBSeek(xFilial("SA1")+PadL(StrTran(StrTran(StrTran(AllTrim(_alinha[7]),".",""),"/",""),"-",""),14,"0"))) 

			aAdd(_aDados, _alinha )
		 	aAdd(_aMuda,{.F.,AllTrim(SA1->A1_CGC),SA1->A1_COD,SA1->A1_LOJA,SubStr(AllTrim(SA1->A1_NOME),1,20),SubStr(AllTrim(SA1->A1_NREDUZ),1,15),"-Essa linha ("+StrZero(_nI,6)+") nao tem o minimo de 7 colunas ("+AllTrim(Str(Len(_alinha)))+") : ["+_ctexto+"]","" })

		EndIf
		
		FT_FSKIP()
		
		_nI++

	EndDo
	
	If Len(_aDados) = 0
	
		U_ITMsg("Arquivo não está no layout da Chep","Atenção",,1)
		
	Else
	
		_cexcecao := U_ITGETMV("ITNCHE",'000001;005098;001632')
		_ntot2 := 0
		oproc2:cCaption := ("Abrindo cadastro de clientes...")
		ProcessMessages()

		_cQuery2 	:= " 			SELECT COUNT(*) CONTA FROM 	" + RetSqlName("SA1")+ " SA1 WHERE "
 	 	_cQuery2 	+= "							         	       SA1.D_E_L_E_T_ = ' ' AND "
 		_cQuery2 	+= "													 SA1.A1_COD NOT IN "+ FormatIn( _cexcecao , ";") + " AND"  
 		_cQuery2 	+= "													 SA1.A1_PESSOA = 'J' AND"  
 		_cQuery2 	+= "													 SA1.A1_I_CCHEP <> ' ' "

 		
 		TcQuery _cQuery2 New Alias "SA1T"

		_ntot2 := SA1T->CONTA
		
		SA1T->(DBCloseArea())
		
		_cQuery2 	:= " 			SELECT  A1_CGC,A1_LOJA,A1_COD,A1_NOME,A1_NREDUZ FROM 	" + RetSqlName("SA1")+ " SA1 WHERE "
 	 	_cQuery2 	+= "							         	       SA1.D_E_L_E_T_ = ' '  AND "
 		_cQuery2 	+= "													 SA1.A1_COD	NOT IN "+ FormatIn( _cexcecao , ";") + " AND"  
 		_cQuery2 	+= "													 SA1.A1_PESSOA = 'J' AND"  
 		_cQuery2 	+= "													 SA1.A1_I_CCHEP <> ' ' "
	
 		TcQuery _cQuery2 New Alias "SA1T"
		
		SA1T->(DBGoTop())
		_ncc := 1

		While !(SA1T->(Eof()))
		
			oproc2:cCaption := ("Processando cadastro de clientes, registro " + StrZero(_ncc,6) + " de " + StrZero(_ntot2,6) + "...")
			ProcessMessages()
			
			//"GLID,Razão Social,Endereço,CEP,Estado,Cidade,CNPJ,Account Status, Date ,AFFILIATION"
			_nposi := aScan(_aDados,{|_vAux|PadL(StrTran(StrTran(StrTran(AllTrim(_vAux[7]),".",""),"/",""),"-",""),14,"0")== PadL(AllTrim(SA1T->A1_CGC),14,'0') }) 
			
			If _nposi == 0
			
			 	aAdd(_aMuda,{.T.,AllTrim(SA1T->A1_CGC),;
				             SA1T->A1_COD,;
							 SA1T->A1_LOJA,;
							 SubStr(AllTrim(SA1T->A1_NOME),1,20),;
							 SubStr(AllTrim(SA1T->A1_NREDUZ),1,15),;
							 "Desativar como cliente CHEP",;
							 " "})
			 	
			EndIf
			
		
			SA1T->(DBSkip())
			_ncc++
			
		EndDo
		
		SA1T->(DBCloseArea())	
	
		If Len(_aMuda) > 0 .And. U_ITListBox( 'Ajustes a serem realizados no cadastro:' , {" ",'CNPJ','Código','Loja','Razão Social','Nome Fantasia','Ajuste a realizar',"Atualizar com:"} , _aMuda , .T. , 4 , 'Os seguintes ajustes serão efetivados: ' )

		   _aMudAux:=ACLONE(_aMuda)
		   _aMuda:={}
		   For nI := 1 TO Len(_aMudAux)
		       _aLinhaM:={}
			   If _aMudAux[nI,1]//SÓ LEVA OS .T.
			      For _nip := 2 to Len(_aMudAux[nI])//TIRA A PRIMIERA COLUNA LOGICA
				      aAdd(_aLinhaM,_aMudAux[nI,_nip])
			      Next
			      aAdd(_aMuda, _aLinhaM)//TIRA A PRIMIERA COLUNA LOGICA
			   EndIf
		   Next
		
			_nip := 1
			
			_dDataImp := Date()
            _cHoraImp := Time()

			While _nip <= Len(_aMuda)
			
				oproc2:cCaption := ("Atualizando cadastro de clientes, registro " + StrZero(_nip,6) + " de " + StrZero(Len(_aMuda),6) + "...")
				ProcessMessages()
				
				If LEFT(_aMuda[_nip][6],1) == "-"// POR GARANTIA
				   _nip++
				   Loop
				EndIf

				SA1->(DBSetOrder(3))
				If SA1->(DBSeek(xFilial("SA1")+AllTrim(_aMuda[_nip][1])))				
				
					While AllTrim(SA1->A1_CGC) == AllTrim(_aMuda[_nip][1])
					
	 					_cstatus := " "
						_aITASA1 := U_ITIniLog( 'SA1')	                   
						
						If _aMuda[_nip][6] == "Desativar como cliente CHEP"
						
							_cstatus := "DESATIVADO"
							RecLock("SA1",.F.)
							SA1->A1_I_CCHEP := " "
							SA1->A1_I_CHEP := "P"
							SA1->A1_I_PALET := "N"
							SA1->(MSUnLock())
							U_AOMS076G()
					        U_ITGrvLog( _aITASA1 , "SA1" , 1 , SA1->( A1_FILIAL + A1_COD + A1_LOJA ) , "A" , _cCodUsr, Date() , Time() )           
				 
						EndIf
				
						If SubStr(AllTrim(_aMuda[_nip][6]),1,9) == "Atualizar"

							_cstatus := "ATIVADO"
							RecLock("SA1",.F.)
							SA1->A1_I_CCHEP := AllTrim(_aMuda[_nip][7])
							SA1->A1_I_CHEP := "C"
							SA1->A1_I_PALET := "S"
							SA1->(MSUnLock())
							U_AOMS076G()
							U_ITGrvLog( _aITASA1 , "SA1" , 1 , SA1->( A1_FILIAL + A1_COD + A1_LOJA ) , "A" , _cCodUsr, Date() , Time() )           
				
						EndIf
						
						RecLock("ZGM",.T.)
						ZGM->ZGM_CGC    := SA1->A1_CGC
						ZGM->ZGM_DATA   := _dDataImp //Date()
						ZGM->ZGM_HORA   := _cHoraImp //Time()
						ZGM->ZGM_ARQUIV := MV_PAR01
						ZGM->ZGM_USER   := cUserName
						ZGM->ZGM_CLIENT := SA1->A1_COD
						ZGM->ZGM_LOJA   := SA1->A1_LOJA
						ZGM->ZGM_IDCHEP := AllTrim(_aMuda[_nip][7])
						ZGM->ZGM_STATUS := _cstatus
						ZGM->(MSUnLock())
				
						SA1->(DBSkip())
						
					EndDo
				
						
				EndIf

				_nip++
			
			EndDo
            
			If ValType(oproc2) = "O"
			   oproc2:cCaption := ("Gerando Relatório de Processamento...")
			   ProcessMessages()
			EndIf 

            _cQry := " SELECT C5_FILIAL, "    // Filial
            _cQry += " C5_NUM, "      // Código do Pedido               
            _cQry += " C5_EMISSAO, "  // Dt. Emissão do Pedido
            _cQry += " C5_I_OPER, "   // Operação
            _cQry += " C5_I_NOME, "   // Razão Social
            _cQry += " A1_I_CCHEP, "  // Código Chep
            _cQry += " C5_I_TIPCA, "  // Tipo de Carga (Mostrar a Descrição)
            _cQry += " C5_I_PEDGE, "  // Ped. Ger. Pal
            _cQry += " C5_I_PEDPA, "  // Gera Palete ? 
            _cQry += " C5_I_NPALE, "  // Nr.Ped Palete
			_cQry += " ZGM_STATUS "
            _cQry += " FROM " + RetSqlName("SC5") + " SC5, " + RetSqlName("SA1") + " SA1, " + RetSqlName("ZGM") + " ZGM "
            _cQry += " WHERE SC5.D_E_L_E_T_ = ' ' AND SA1.D_E_L_E_T_ = ' ' AND ZGM.D_E_L_E_T_ = ' ' "
			_cQry += " AND C5_CLIENTE = ZGM_CLIENT "
            _cQry += " AND C5_LOJACLI = ZGM_LOJA "
			_cQry += " AND A1_COD  = ZGM_CLIENT "
            _cQry += " AND A1_LOJA = ZGM_LOJA "
            _cQry += " AND C5_NOTA = ' ' "
            _cQry += " AND C5_TIPO = 'N' "
			_cQry += " AND ZGM_DATA = '" + DToS(_dDataImp) + "' " 
			_cQry += " AND ZGM_HORA = '" + _cHoraImp + "' "       
			_cQry += " AND (ZGM_STATUS = 'ATIVADO' OR ZGM_STATUS = 'DESATIVADO') "

            _cQry += " ORDER BY C5_FILIAL, C5_NUM "

            MPSysOpenQuery( _cQry , _cAliasQry)
            DBSelectArea(_cAliasQry)  //O MPSysOpenQuery() NÃO DEIXA NA AREA NOVA
            Count To _nTotRegs
            
			If _nTotRegs > 0
			   _aDadosRel := {}
			   (_cAliasQry)->(DBGoTop())
			   DAI->(DBSetOrder(4)) // DAI_FILIAL+DAI_PEDIDO+DAI_COD+DAI_SEQCAR
               
			   _nip := 1

			   While ! (_cAliasQry)->(Eof())
                  If ValType(oproc2) = "O"
				     oproc2:cCaption := ("Gerando Relatório de Processamento, registro " + StrZero(_nip,6) + " de " + StrZero(_nTotRegs,6) + "...")
				     ProcessMessages()
				  EndIf 

               	  _aLinha := {}
                  aAdd(_aLinha, (_cAliasQry)->C5_FILIAL)   // Filial
				  aAdd(_aLinha, (_cAliasQry)->C5_NUM)      // Código do Pedido  
				  aAdd(_aLinha, (_cAliasQry)->C5_EMISSAO)  // Dt. Emissão do Pedido
				  aAdd(_aLinha, (_cAliasQry)->C5_I_OPER)   // Operação
				  aAdd(_aLinha, (_cAliasQry)->C5_I_NOME)   // Razão Social
				  aAdd(_aLinha, (_cAliasQry)->A1_I_CCHEP) // Código Chep
				  
				  If (_cAliasQry)->C5_I_TIPCA == "1"
				     aAdd(_aLinha, "Paletizada") // Tipo de Carga (Mostrar a Descrição) 1=Paletizada;2=Batida
				  ElseIf (_cAliasQry)->C5_I_TIPCA == "2"
				     aAdd(_aLinha, "Batida")
				  Else 
                     aAdd(_aLinha, " ")
				  EndIf 
				  
				  aAdd(_aLinha, (_cAliasQry)->C5_I_PEDGE)  // Ped. Ger. Pal
				  
				  If (_cAliasQry)->C5_I_PEDPA == "S"
				     aAdd(_aLinha, "Sim" ) // Gera Palete ? 
				  Else 
                     aAdd(_aLinha, "Não" ) // Gera Palete ? 
				  EndIf 

				  aAdd(_aLinha, (_cAliasQry)->C5_I_NPALE ) // Nr.Ped Palete

                  If DAI->(MsSeek((_cAliasQry)->C5_FILIAL + (_cAliasQry)->C5_NUM))
                     aAdd(_aLinha, DAI->DAI_COD)  // Ordem de Carga
                     aAdd(_aLinha, DAI->DAI_DATA) // Dt. Ordem de Carga
                  Else 
                     aAdd(_aLinha, Ctod("  /  /  "))  // Ordem de Carga
                     aAdd(_aLinha, Ctod("  /  /  "))  // Dt. Ordem de Carga
				  EndIf 
                  
				  aAdd(_aLinha, (_cAliasQry)->ZGM_STATUS)

                  aAdd(_aDadosRel,_aLinha)

                  (_cAliasQry)->(DBSkip())
				  
				  _nip += 1

               EndDo 
			   
			   //_cTitulo :='LISTA DE PEDIDOS ALTERADOS NA IMPORTAÇÃO CHEP'
			   _cTitulo := 'LISTA DE PEDIDOS PENDENTES COM DADOS DO CLIENTE CHEP ALTERADO'
               _cMsgTop := Nil
               _aSize   := Nil
               
               _aCab := {"Filial","Código do Pedido", "Dt. Emissão do Pedido", "Operação", "Razão Social" , "Código Chep",;
                         "Tipo de Carga", "Ped. Ger. Pal", "Gera Palete ?", "Nr.Ped Palete", "Ordem de Carga", "Dt. Ordem de Carga","Status"}

               //                ,_aCols,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca,_bLegenda,_lHasOk,_bHeadClk)
               U_ITListBox(_cTitulo,_aCab,_aDadosRel, .T.    , 1    ,_cMsgTop ,          ,_aSize  ,         ,     ,        ,          ,       ,        ,          ,           ,         ,       ,         )
            
			Else 
               U_ITMsg("Nenhum dado foi atualizado.","Atenção",,1)
			EndIf 

			If Select(_cAliasQry) > 0
               (_cAliasQry)->(DBCloseArea())
            EndIf

			U_ITMsg("Processamento concluído com sucesso","Atenção",,2)
			
		ElseIf Len(_aMuda) == 0
		
			U_ITMsg("Não há registros para atualizar","Atenção",,3)
		
		Else
		
			U_ITMsg("Processamento cancelado pelo usuario", "Atenção",,1)
		
		EndIf
		
	EndIf	
	
EndIf

FT_FUSE()

ferase(_cPathTemp+"csvtemp.csv")
ferase(_cPathTemp+"xlstemp.xls")
ferase(_cPathTemp+"converzz.vbs")

Return
