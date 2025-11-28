/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |15/02/2024| Chamado 46302. Andre. Criada a nova opcao de Origem (MV_PAR07): Estrutura e Consumo.
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
Lucas Borges  |09/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
===============================================================================================================================
*/

#Include "TOTVS.ch"  

/*
===============================================================================================================================
Programa----------: MEST016
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 27/09/2018
Descrição---------: Ajuste de Saldos de estoques para distribuicao dos custos nas OP's - CHAMADO 27301
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST016()

Local d_Fecha:= GetMv('MV_ULMES')
Local cPerg  :="MEST016"

Private _aItalac_F3:={}

While .T.

	If !Pergunte(cPerg,.T.)
		Return
	EndIf

   If MV_PAR02 < d_Fecha
	  U_ITMsg('A data inicial deve ser maior que a data do ultimo fechamento: '+DToC(d_Fecha), 'ATENÇÃO',,1)
	  Loop
   ElseIf MV_PAR02 > MV_PAR03
	  U_ITMsg('A data inicial deve ser menor que a data final','ATENÇÃO',,1)
	  Loop
   ElseIf Empty(MV_PAR04)
	  U_ITMsg('É obrigadotorio informar o codigo do produto','ATENÇÃO',,1)
	  Loop
   EndIf  

   _aOProd:={}
   _nTotOPs:=0
   _nTotPR0:=0
   _nTotRat:=0
   _nTotVlN:=0
   _cCustos:=""

   FWMsgRun( ,{|oProc| MEST16Ler(oProc) } , "Aguarde...", "Lendo dados..."  )

   If Select("QRT") > 0
      DBSelectArea("QRT")
      DBCloseArea()
   EndIf

   If Len(_aOProd) = 0
      Loop
   EndIf
     
   _cMsgTop:="Totais das OPs, Litros: ;"
   _cMsgTop+="Valor Rateio por produto: "+AllTrim(TRANS(MV_PAR01,"@E 999,999,999,999,999,999.999"))+"; "
   _cMsgTop+=" C.C.(s): "+_cCustos

   Exit	

EndDo

While .T.

//User Function ITListBox( _cTitAux ,
   _lOK:=U_ITListBox( 'OPs Filtradas (MEST016): '+_cMsgTop ,;                                                                        // _aHeader , _aCols,_lMaxSiz,_nTipo ,_cMsgTop ,_lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons )
                     {'OP + CC','Data Emissao','Produto [PR0]','Qtde Apontada','Produto [RE1]','Qtde Consumida','Reteio','Valor Novo','Quantidade Empenho'},_aOProd,.T.     ,1      ,_cMsgTop ,         ,;
                     {       55,            55,             50,             50,             50,              50,      50,          50,                  50})//,, _bOK,_bCancel )
   If _lOK 
   
      If U_ITMsg("CONFIRMA A GRAVAÇÃO DOS VALORES ????",'Atenção!',,2,2,2)

         FWMsgRun( ,{|oProc| _lOK:=MEST16Grv(oProc) } , "Aguarde...", "Gravando dados..."  )

         If !_lOK
            Loop
         EndIf   
      Else   
         Loop
      EndIf   

   EndIf  

   Exit

EndDo   

Return

/*
===============================================================================================================================
Programa----------: MEST16Ler
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 27/09/2018
Descrição---------: Grava os dados da OP
Parametros--------: oProc
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
Static Function MEST16Grv(oProc)
Local nCotaGRV:=0 , P
Local _nConta:=0

_cTotOPs:=AllTrim(Str(Len(_aOProd)))
_nTam:=Len(_cTotOPs)+1

For P := 1 TO Len(_aOProd)

   _nConta++
   oProc:cCaption := "2/2-Gravando OP: "+SD3->D3_OP+" - "+Str(_nConta,_nTam)+" de "+_cTotOPs
   ProcessMessages()

   If _aOProd[P,10] = 0
      Loop
   EndIf
   SD3->(DBGoTo( _aOProd[P,10] ))
   SD3->(RecLock("SD3",.F.))
   SD3->D3_I_QTORI:= SD3->D3_QUANT
   SD3->D3_QUANT  := _aOProd[P,12]
   SD3->(MSUnLock())  
   nCotaGRV++

   If _aOProd[P,11] = 0
      Loop
   EndIf
   SD4->(DBGoTo( _aOProd[P,11] ))
   SD4->(RecLock("SD4",.F.))
   SD4->D4_I_QTORI:=SD4->D4_QTDEORI
   SD4->D4_QTDEORI:= _aOProd[P,12]
   SD4->(MSUnLock())  

Next

U_ITMsg(AllTrim(Str(nCotaGRV))+" Resgistros atualizados com sucesso",'FINAL',_cMsgTop,2)

Return .T.

/*
===============================================================================================================================
Programa----------: MEST16Ler
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 27/09/2018
Descrição---------: Ler os dados da OP
Parametros--------: oProc
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
Static Function MEST16Ler(oProc)
Local nCountRec , P , _nVlrDif

Local _cPicT3:=AVSX3("D3_QUANT",6)
Local _cPicT4:=AVSX3("D4_QTDEORI",6)
Local _cPicTR:="@E 999,999,999,999,999,999.999"
Local _cCodFiltro:=""//"08000000051"
Local _Query := ""  , E
_cCustos:="Todos"

If MV_PAR07 = 1 //ESTRUTURA

   _Query += "        SELECT D3_CC FROM "+RETSQLNAME("SD3")+" SD3 "
   _QUERY += "                 WHERE SD3.D_E_L_E_T_ = ' ' AND D3_FILIAL = '"+xFilial("SD3")+"' " 
   _QUERY += "                   AND SD3.D3_CF = 'PR0' AND D3_ESTORNO <> 'S' "
   _Query += "                AND SD3.D3_COD = '"+AllTrim(MV_PAR04)+"'"
   If Empty(MV_PAR03)
      _Query += "                AND  SD3.D3_EMISSAO >= '"+DToS(MV_PAR02)+"' " 
   Else
      _Query += "                AND  SD3.D3_EMISSAO BETWEEN '"+DToS(MV_PAR02)+"' AND '"+DToS(MV_PAR03)+"' " 
   EndIf
   _Query += " GROUP BY D3_CC "
   _Query := ChangeQuery(_Query)

   If Select("QRT") > 0
      QRT->(DBCloseArea())
   EndIf
   oProc:cCaption := "Lendo OPs Pai, Aguarde..."
   ProcessMessages()
   
   MPSysOpenQuery( _Query, "QRT" ) 
   
   QRT->(DBGoTop())
   
   _cCustos:=""
   While QRT->(!Eof())
   
      If !QRT->D3_CC $ _cCustos
         _cCustos+=QRT->D3_CC+";"
      EndIf   
      QRT->(DBSkip())
   	
   EndDo
   
   If Empty(_cCustos)
      U_ITMsg("Não foram encontrados dados para essa seleção",'ATENÇÃO',"Selecione outros dados no filtro e tene novamente",1)
      Return .F.
   EndIf
   
   _cCustos:=LEFT(_cCustos,Len(_cCustos)-1)
   
   If Select("QRT") > 0
      QRT->(DBCloseArea())
   EndIf
   
   SB1->(DBSetOrder(1))

//If MV_PAR07 = 1 //ESTRUTURA

   _cTeste:=" PAI "+CHR(13)+CHR(10)
   nEstru := 0
   aEstrutura:={}
   _aCodFiltro:={}
   aEstrProd:=Estrut(AVKEY(MV_PAR04,"G1_COD"),1) 
   For P := 1 TO Len(aEstrProd)
       _cTeste += ARRTOKSTR(aEstrProd[P])
       SB1->(DBSeek(xFilial()+aEstrProd[P,3]))
       If aEstrProd[P,1] = 1 .And. SB1->B1_TIPO $ "'PP','PI','MP','PA'" .And. SB1->B1_GRUPO $ "'0003','0002','0006','0800','0814'"
          _cCodFiltro+=aEstrProd[P,3]+";"
          aAdd(_aCodFiltro,aEstrProd[P,3])
          _cTeste += "; X "
       EndIf
       _cTeste += CHR(13)+CHR(10)
   Next
   
   _aCodNivel:={}
   For E := 1 TO Len(_aCodFiltro)
   	_cCodAux:=_aCodFiltro[E]
   	nEstru := 0
   	aEstrutura:={}
   	aEstrProd:=Estrut(AVKEY(_cCodAux,"G1_COD"),1)
   	_cTeste+=" FILHO 1 "+CHR(13)+CHR(10)
   	_cCodNivel:=""
   	For P := 1 TO Len(aEstrProd)
   		_cTeste+=ARRTOKSTR(aEstrProd[P])
   		SB1->(DBSeek(xFilial()+aEstrProd[P,3]))
   		If aEstrProd[P,1] = 1 .And. SB1->B1_TIPO $ "'PP','PI','MP'" .And. SB1->B1_GRUPO $ "'0003','0002','0006','0800','0814'"
   			_cCodFiltro+=aEstrProd[P,3]+";"
   			aAdd(_aCodNivel,aEstrProd[P,3])
   			_cTeste += "; X "
   		EndIf
   		_cTeste += CHR(13)+CHR(10)
   	Next
   Next
   
   For E := 1 TO Len(_aCodNivel)
   	_cCodNivel:=_aCodNivel[E]
   	nEstru := 0
   	aEstrutura:={}
   	aEstrProd:=Estrut(AVKEY(_cCodNivel,"G1_COD"),1)
   	_cTeste+=" FILHO 2 "+CRLF
   	_cCodNivel:=""
   	For P := 1 TO Len(aEstrProd)
   		_cTeste+=ARRTOKSTR(aEstrProd[P])
   		SB1->(DBSeek(xFilial()+aEstrProd[P,3]))
   		If aEstrProd[P,1] = 1 .And. SB1->B1_TIPO $ "'PP','PI','MP'" .And. SB1->B1_GRUPO $ "'0003','0002','0006','0800','0814'"
   			_cCodFiltro+=aEstrProd[P,3]+";"
   			_cTeste += "; X "
   		EndIf
   		_cTeste += CRLF
   	Next
   Next
   
   _cTeste:=StrTran(_cTeste,"|",";")
   
   _Query := ""
   _QUERY += "         SELECT D3_EMISSAO, D3_OP, D3_COD, D3_I_QTORI, D3_QUANT, R_E_C_N_O_ REC_SD3 FROM "+RETSQLNAME("SD3")+" SD3 "
   _QUERY += "                WHERE  SD3.D_E_L_E_T_ = ' ' AND D3_FILIAL = '"+xFilial("SD3")+"' " 
   _QUERY += "                  AND (SD3.D3_CF = 'RE1'  "//CONSUMIDO
   _QUERY += "                    OR SD3.D3_CF = 'PR0') "//PRODUZIDO
   _QUERY += "                  AND  SD3.D3_ESTORNO <> 'S' AND SD3.D3_I_ORIGE <> 'MATA685' "
   _Query += "                  AND  SD3.D3_COD IN "+FormatIn(_cCodFiltro,";")
   _Query += "                  AND  SD3.D3_CC  IN "+FormatIn(_cCustos,";")
   If !Empty(MV_PAR05)
      _Query += "               AND  SD3.D3_OP  IN "+FormatIn(AllTrim(MV_PAR05),";")
   EndIf
   If Empty(MV_PAR03)
      _Query += "               AND  SD3.D3_EMISSAO >= '"+DToS(MV_PAR02)+"' " 
   Else
      _Query += "               AND  SD3.D3_EMISSAO BETWEEN '"+DToS(MV_PAR02)+"' AND '"+DToS(MV_PAR03)+"' " 
   EndIf
   
   _QUERY += " ORDER BY D3_EMISSAO , D3_OP , D3_COD "

Else//MV_PAR07 - CONSUMO

   _QUERY := ""
   _QUERY += " SELECT D3_EMISSAO, D3_OP, D3_COD, D3_I_QTORI, D3_QUANT, R_E_C_N_O_ REC_SD3 FROM "+RETSQLNAME("SD3")+" SD3 "
   _QUERY += "                WHERE SD3.D_E_L_E_T_ = ' ' AND D3_FILIAL = '"+xFilial("SD3")+"' " 
   _QUERY += "                  AND SD3.D3_CF = 'RE1'
   _QUERY += "                  AND SD3.D3_TIPO IN ('MP','PP','PI','PA')
   _QUERY += "                  AND SD3.D3_GRUPO IN ('0003','0002','0006','0800','0814')
   _QUERY += "                  AND SD3.D3_ESTORNO <> 'S' AND SD3.D3_I_ORIGE <> 'MATA685' "
   If !Empty((MV_PAR08))
      _Query += "               AND SD3.D3_COD IN "+FormatIn(AllTrim(MV_PAR08),";")
   EndIf
   If !Empty(MV_PAR05)
      _Query += "               AND SD3.D3_OP  IN "+FormatIn(AllTrim(MV_PAR05),";")
   Else
      _Query += "               AND SD3.D3_OP  IN (SELECT D3_OP FROM " + RetSqlName("SD3") + " WHERE D_E_L_E_T_ = ' '  "
      _Query += "                                     AND  D3_ESTORNO <> 'S' AND D3_CF = 'PR0' AND D3_COD = '"+AllTrim(MV_PAR04)+"' ) "
      If Empty(MV_PAR03)
         _Query += "                                  AND  SD3.D3_EMISSAO >= '"+DToS(MV_PAR02)+"' " 
      Else
         _Query += "                                  AND  SD3.D3_EMISSAO BETWEEN '"+DToS(MV_PAR02)+"' AND '"+DToS(MV_PAR03)+"' " 
      EndIf
   EndIf
   _QUERY += " ORDER BY D3_EMISSAO , D3_OP , D3_COD "

EndIf

oProc:cCaption := "Lendo OPs Filhas, Aguarde..."
ProcessMessages()

_Query := ChangeQuery(_Query)
MPSysOpenQuery( _Query, "QRT" ) 

DBSelectArea("QRT")
COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query
		
If nCountRec = 0

   U_ITMsg("Não tem registros para esses filtros: Cods: "+_cCodFiltro+", CC: "+_cCustos,'Atenção!',"Seleciones outros filtros e tente novamente",1)
   Return .F.

EndIf

_aDados:={}
QRT->(DBGoTop())
While QRT->(!Eof())

   If !Empty(QRT->D3_I_QTORI)
	   aAdd(_aDados, { QRT->D3_OP,DToC(SToD(QRT->D3_EMISSAO)),QRT->D3_COD } )
   EndIf   

	QRT->(DBSkip())
	
EndDo

                                       // _aHeader , _aCols,_lMaxSiz,_nTipo ,_cMsgTop ,_lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons )
If Len(_aDados) > 0
   bBloco:={||U_ITListBox( 'OPs já rateadas (MEST016) ',;
                     {'OP','Data Emissao','Produto'},_aDados,.F.     ,1      ,         ,         ,;
                     { 50,            55,        50})  }//,, _bOK,_bCancel )
   If !U_ITMsg("Existem OPs que já foram rateadas",'Atenção!',"Deseja continuar mesmo assim? ",3,2,2,,,,bBloco)
      Return .F.
   EndIf
EndIf

QRT->(DBGoTop())
_aOProd:={}
_nTotVlN:=_nTotOPs:=_nConta:=0
_cTotOPs:=AllTrim(Str(nCountRec))
_nTam:=Len(_cTotOPs)+1
_aTotProds:={}

SD4->(DBSetOrder(2))

While QRT->(!Eof())
	
	SD3->(DBGoTo( QRT->REC_SD3 ))
	
	_nConta++
	oProc:cCaption := "1/2-Lendo OP: "+SD3->D3_OP+" - "+Str(_nConta,_nTam)+" de "+_cTotOPs
	ProcessMessages()

	//*********************************   PRODUTO PAI  ****************************
	If SD3->D3_CF = "PR0"
		
			nQtdeSD4:=0
			nRecSD4 :=0
		                //OP + CC                           ,Data                 ,           ,Qtde Apontada   ,Prod Filho ,Qtde Consumida              ,Rateio          ,Valor Novo      ,Qtde Emepnho           ,REC SD3      ,REC SD4 ,Valor para gravar
		                //01                                ,02                   ,03         ,04              ,05         ,06                          ,07              ,08              ,09                     ,10           ,11      ,12
		aAdd(_aOProd, { AllTrim(SD3->D3_OP)+" - "+SD3->D3_CC,DToC(SD3->D3_EMISSAO),SD3->D3_COD,TRANS(SD3->D3_QUANT,_cPicT3),""         ,TRANS(0,_cPicT3),TRANS(0,_cPicTR),TRANS(0,_cPicTR),TRANS(nQtdeSD4,_cPicT4), QRT->REC_SD3, nRecSD4,0 } )
		_nTotPR0+=SD3->D3_QUANT
		
	ElseIf SD3->D3_CF = "RE1"
		
		//*********************************   PRODUTO FILHO  ****************************
		If SD4->(DBSeek(SD3->D3_FILIAL+SD3->D3_OP+SD3->D3_COD+SD3->D3_LOCAL))
			nQtdeSD4:=SD4->D4_QTDEORI
			nRecSD4 :=SD4->(RECNO())
		Else
			nQtdeSD4:=0
			nRecSD4 :=0
		EndIf
		                //OP + CC                           ,Data                 ,  ,Qtde Apontada   ,Prod Filho ,Qtde Consumida              ,Rateio          ,Valor Novo      ,Qtde Emepnho           ,REC SD3      ,REC SD4 ,Valor para gravar
		                //01                                ,02                   ,03,04              ,05         ,06                          ,07              ,08              ,09                     ,10           ,11      ,12
		aAdd(_aOProd, { AllTrim(SD3->D3_OP)+" - "+SD3->D3_CC,DToC(SD3->D3_EMISSAO),"",TRANS(0,_cPicT3),SD3->D3_COD,TRANS(SD3->D3_QUANT,_cPicT3),TRANS(0,_cPicTR),TRANS(0,_cPicTR),TRANS(nQtdeSD4,_cPicT4), QRT->REC_SD3, nRecSD4,0                } )
		_nTotOPs+=SD3->D3_QUANT
		
	EndIf
	
	If (nPos:=aScan(_aTotProds, {|P| P[1] == SD3->D3_COD+SD3->D3_CF})) = 0
                        //1-CODIGO               ,2-QUATANTIDADE .3- MAIOR,4-POSICAO,5-SOMA RATEIO,6-SOMA QTDE NOVA
		aAdd(_aTotProds,{ SD3->D3_COD+SD3->D3_CF , SD3->D3_QUANT ,   0    ,    0    ,     0       ,   0            })
	Else
		_aTotProds[nPos,2]+=SD3->D3_QUANT
	EndIf
	
	QRT->(DBSkip())
	
EndDo

_nTotVlN:=_nTotRat:=_nConta:=0
_cTotOPs:=AllTrim(Str(Len(_aOProd)))
_nPosMaior:=0
MV_PAR06:=MV_PAR06

For P := 1 TO Len(_aOProd)

   SD3->(DBGoTo( _aOProd[P,10] ))

   _nConta++
   oProc:cCaption := "2/2-Calculando OP: "+SD3->D3_OP+" - "+Str(_nConta,_nTam)+" de "+_cTotOPs
   ProcessMessages()

	If (nPos:=aScan(_aTotProds, {|P| P[1] == SD3->D3_COD+SD3->D3_CF })) <> 0
      _nRateio    := Round(MV_PAR01*(SD3->D3_QUANT/_aTotProds[nPos,2]),3)

      _aTotProds[nPos,5]+= _nRateio//SOMATORIA RATEIO 

      If _nRateio > _aTotProds[nPos,3]
        _aTotProds[nPos,3]:=_nRateio
        _aTotProds[nPos,4]:=P
      EndIf   

      If MV_PAR06 = 1//1-Acrescimo,2-Abatimento
         _nRateio:=(_nRateio*-1)
      EndIf

      _aTotProds[nPos,6]+= (SD3->D3_QUANT+_nRateio)//SOMATORIA VALOR NOVO
      _aOProd[P,07]:= TRANS(_nRateio,_cPicT3)//Rateio
      _aOProd[P,08]:= TRANS(SD3->D3_QUANT+_nRateio,_cPicT3)//Valor Novo
      _aOProd[P,12]:= SD3->D3_QUANT+_nRateio//Valor para grava na tabela na integra
   EndIf   

Next

For P := 1 TO Len(_aTotProds)
	
	If (MV_PAR01 - _aTotProds[P,5] <> 0)
		
		_nVlrDif:=(MV_PAR01 - _aTotProds[P,5])//_nTotRat
		_nPosMaior:=_aTotProds[P,4]
		
		_aTotProds[P,5]+= _nVlrDif//SOMA RATEIO

        If MV_PAR06 = 1//1-Acrescimo,2-Abatimento
           _nVlrDif:=(_nVlrDif*-1)
         EndIf
		_aTotProds[P,6]+= _nVlrDif//SOMA QTDE NOVA
		_aOProd[_nPosMaior,07]:= TRANS( Val( StrTran(StrTran(_aOProd[_nPosMaior,7],".",""),",",".") )+_nVlrDif ,_cPicT3)//Rateio
		_aOProd[_nPosMaior,08]:= TRANS( Val( StrTran(StrTran(_aOProd[_nPosMaior,8],".",""),",",".") )+_nVlrDif ,_cPicT3)//Valor Novo
		_aOProd[_nPosMaior,12]:= _aOProd[_nPosMaior,12]+_nVlrDif//Valor para grava na tabela na integra
		
	EndIf
	
	//                //1-CODIGO               ,2-QUATANTIDADE .3- MAIOR,4-POSICAO,5-SOMA RATEIO,6-SOMA QTDE NOVA
	//aAdd(_aTotProds,{ SD3->D3_COD+SD3->D3_CF , SD3->D3_QUANT ,   0    ,    0    ,     0       ,   0            })
	
	aAdd(_aOProd, {"---------------------","---------------------","---------------------","","","","","","",0,0,0} )

	_cQtde:=AllTrim(TRANS(_aTotProds[P,2],"@E 999,999,999,999,999,999.999"))
	aAdd(_aOProd, {"Total Produto:" ,_aTotProds[P,1],_cQtde,"","","","","","",0,0,0} )
	
	_cQtde:=AllTrim(TRANS(_aTotProds[P,5],"@E 999,999,999,999,999,999.999"))
	aAdd(_aOProd, {"Total Rateio:"  ,_aTotProds[P,1],_cQtde,"","","","","","",0,0,0} )
	
	_cQtde:=AllTrim(TRANS(_aTotProds[P,6],"@E 999,999,999,999,999,999.999"))
	aAdd(_aOProd, {"Total Qtd Novo:",_aTotProds[P,1],_cQtde,"","","","","","",0,0,0} )

Next
                                                                 '
Return .T.
