/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |25/07/2017| Chamado 20915. Ajuste no SELECT e zerar a variavel _nVlrMix e recalulo com ZLJ
Alex Wallauer |15/08/2017| Chamado 21123. Adicionado tratamento para recepções manuais
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MEST012 
Autor-------------: Alexandro Ferreira
Data da Criacao---: 04/08/2016 
Descrição---------: Rotina de recálculo de custo de recepção do leite próprio - Chamado 15507
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/                     
User Function MEST012()

Local _cPerg   	:="MEST012"
Local _bProcess	:= nil
Local _oprocess	:= nil

Private _lsai		:= .F.

While .not. _lsai

	_lsai := .T.

	//============================================
	//Cria interface principal
	//============================================
	_bProcess    := {|_oprocess| MEST012E(_oprocess) }
	tNewProcess():New( _cPerg, "Rotina de recálculo do custo de entrada de recepção do leite próprio",;
								 _bProcess, "Rotina de recálculo do custo de entrada de recepção do leite próprio","MEST012")
							 
EndDo

Return	
	
/*
===============================================================================================================================
Programa----------: MEST012E 
Autor-------------: Josué Prestes
Data da Criacao---: 04/08/2016 
Descrição---------: Processamento de recálculo de custo de entrada do leite próprio
Parametros--------: _oprocess
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST012E(_oprocess)	

Local _cAlias := GetNextAlias()
Local _nDias  := 0
Local _cDiasT := MV_PAR02-MV_PAR01+1
Local _cPicCus:= "@E 999,999,999,999.99"//PesqPict("SD3","D3_CUSTO1")
Local _nVlrMix:= 0,S
Private _aLog 	:= {}

_oProcess:SetRegua1(4)
_oProcess:SetRegua2(4)

_oProcess:IncRegua1("Processando o periodo...")
_oProcess:IncRegua2("Data Inicial: "+DToC(MV_PAR01)+" ate Data Final: "+DToC(MV_PAR02) )

_oProcess:IncRegua1("Processando o periodo...")
_oProcess:IncRegua2("Data Inicial: "+DToC(MV_PAR01)+" ate Data Final: "+DToC(MV_PAR02) )

_dDtini  := MV_PAR01
_dDtfim  := MV_PAR02

If Empty(_dDtini) .Or. Empty(_dDtfim)
   Aviso( 'Atenção!' , "As duas datas devem ser preenchidas" , {'Voltar'} ) 
	_lsai := .F.
   Return .F.
EndIf
_dDtMV_ULMES:= SToD( Posicione("SX6",1,cFilant+"MV_ULMES","X6_CONTEUD") )
If _dDtini <= _dDtMV_ULMES
   Aviso( 'Atenção!' , "Data inicial menor ou igual que a data do fechamento do estoque: [ "+DToC(_dDtMV_ULMES)+" ] " , {'Voltar'} ) 
	_lsai := .F.
   Return .F.
EndIf
If _dDtini > _dDtfim
  Aviso( 'Atenção!' , "Data inicial deve ser menor que a data final" , {'Voltar'} ) 
	_lsai := .F.
  Return .F.
EndIf


_cQuery1:= " SELECT COUNT(DISTINCT SD3.R_E_C_N_O_) TOTAL  "

_cQuery2:= " SELECT DISTINCT SD3.R_E_C_N_O_ REC_SD3 "

_cQuery := " FROM "+ RetSqlName("SD3") +" SD3 "
_cQuery += "INNER JOIN "+ RetSqlName("ZLJ") +" ZLJ ON "
_cQuery += "  SD3.D3_FILIAL||TRIM(SD3.D3_L_ORIG)||SD3.D3_L_SETOR = ZLJ.ZLJ_FILIAL||ZLJ.ZLJ_VIAGEM||ZLJ.ZLJ_SETOR  AND "
_cQuery += "  ZLJ.D_E_L_E_T_ = ' ' AND ZLJ.ZLJ_DTIVIA BETWEEN '"+DToS(MV_PAR01)+"' AND '"+DToS(MV_PAR02)+"' "
_cQuery += "LEFT JOIN "+ RetSqlName("ZLD") +" ZLD ON "
_cQuery += "  SD3.D3_FILIAL||TRIM(SD3.D3_L_ORIG)||SD3.D3_L_SETOR = ZLD.ZLD_FILIAL||ZLD.ZLD_TICKET||ZLD.ZLD_SETOR  AND "
_cQuery += "  ZLD.D_E_L_E_T_ = ' ' AND ZLD.ZLD_DTCOLE BETWEEN '"+DToS(MV_PAR01)+"' AND '"+DToS(MV_PAR02)+"' "
_cQuery += " WHERE  SD3.D_E_L_E_T_ = ' ' AND SD3.D3_ESTORNO <> 'S' "
If !Empty(MV_PAR03)
   _cQuery += " AND SD3.D3_FILIAL IN "+FormatIn( AllTrim(MV_PAR03) , ';' )
EndIf
_cQuery += "    UNION "

_cQuery4 := " FROM "+ RetSqlName("SD3") +" SD3 "
_cQuery4 += "INNER JOIN "+ RetSqlName("ZLD") +" ZLD ON "
_cQuery4 += "  SD3.D3_FILIAL||TRIM(SD3.D3_L_ORIG)||SD3.D3_L_SETOR = ZLD.ZLD_FILIAL||ZLD.ZLD_TICKET||ZLD.ZLD_SETOR  AND "
_cQuery4 += "  ZLD.D_E_L_E_T_ = ' ' AND ZLD.ZLD_DTCOLE BETWEEN '"+DToS(MV_PAR01)+"' AND '"+DToS(MV_PAR02)+"' "
_cQuery4 += " WHERE  SD3.D_E_L_E_T_ = ' ' AND SD3.D3_ESTORNO <> 'S'  AND SubStr(SD3.D3_L_ORIG,1,1) <> 'S' "
If !Empty(MV_PAR03)
   _cQuery4 += " AND SD3.D3_FILIAL IN "+FormatIn( AllTrim(MV_PAR03) , ';' )
EndIf
	
If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf
	
DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery1+_cQuery+_cQuery1+_cQuery4 ) , _cAlias , .F. , .T. )

_oProcess:IncRegua1("Processando o periodo...")
_oProcess:IncRegua2("Data Inicial: "+DToC(MV_PAR01)+" ate Data Final: "+DToC(MV_PAR02) )

(_cAlias)->(DBGoTop())
_nTotal:=(_cAlias)->TOTAL
(_cAlias)->(DBSkip())
_nTotal+=(_cAlias)->TOTAL

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

_cDiasT := AllTrim(Str(_nTotal,10))	
	
DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery2+_cQuery+_cQuery2+_cQuery4 ) , _cAlias , .F. , .T. ) 

_oProcess:IncRegua1("Processando o periodo...")
_oProcess:IncRegua2("Data Inicial: "+DToC(MV_PAR01)+" ate Data Final: "+DToC(MV_PAR02) )

If !MSGYESNO("Serao processados "+AllTrim(Str(_nTotal,10))+" registros. Continua?")
   Return .T.
EndIf

_oProcess:SetRegua1(_nTotal)
_oProcess:SetRegua2(_nTotal)

(_cAlias)-> ( DBGoTop() )
_nAcertos:=0
While !(_cAlias)->( Eof() )

   SD3->(DBGoTo( (_cAlias)->REC_SD3 ) )
		
   _nDias++
   _oProcess:IncRegua1("Processando Data: "+DToC(SD3->D3_EMISSAO))
   _oProcess:IncRegua2("Lendo registro: "+AllTrim(Str(_nDias,10))+" de "+_cDiasT+" ..." )

   If Empty(SD3->D3_L_ORIG)
      (_cAlias)->(DBSkip())
      Loop
   EndIf		
   
   _nValor  := 0
   _cSetorPA:= SD3->D3_L_SETOR 
   _cSetores:= SD3->D3_L_SETOR 

   aAdd( _aLog , {"",;//1
                  SD3->D3_FILIAL,;//2
                  ""            ,;//3 //Data de coleta do ZLD
                  AllTrim(SD3->D3_L_ORIG),;//4
                  SD3->D3_L_SETOR,;//5 Setor Anterior
                  SD3->D3_L_SETOR,;//6 Setores Atualizados
                  TRANSF(SD3->D3_QUANT,PesqPict("SD3","D3_QUANT")),;//7
                  TRANSF(SD3->D3_CUSTO1,_cPicCus),;//8 - 'Custo Anterior'
                  TRANSF(SD3->D3_CUSTO1,_cPicCus),;//9 - 'Custo Recalculado'
                  DToC(SD3->D3_EMISSAO)          })//10 - Data de entrada no Estoque
   nPosCA:=Len(_aLog[1])-1//Posicao do custo total

   ZLD-> ( DBSetOrder(5) )//ZLD_FILIAL+ZLD_TICKET+ZLD_SETOR
   ZLJ-> ( DBSetOrder(2) )//ZLJ_FILIAL+ZLJ_VIAGEM
		
   If LEFT(SD3->D3_L_ORIG,1)  = "S"
      _aSetores:= {}
      _nTotal  := 0 
      _cSetores:=""
		
	  If ZLD->( DBSeek(SD3->D3_FILIAL+AllTrim(SD3->D3_L_ORIG)) )

         MEST012Calc("ZLD")

      ElseIf ZLJ->( DBSeek(SD3->D3_FILIAL+AllTrim(SD3->D3_L_ORIG)) ) 

	         If ZLJ->ZLJ_STATUS = "P"

                MEST012Calc("ZLJ")//Ticket nao efetivado

             ElseIf ZLJ->ZLJ_STATUS = "E"//Ticket efetivado
                _aLog[Len(_aLog),1]:="Ticket efetivado e não tem na ZLD"
                (_cAlias)->(DBSkip())
                Loop
	         Else
                _aLog[Len(_aLog),1]:="Ticket com Status diferente de 'E' e 'P': "+ZLJ->ZLJ_STATUS
                (_cAlias)->(DBSkip())
                Loop
             EndIf          
       
      Else

          _aLog[Len(_aLog),1]:="Ticket nao encontrado"
          
          (_cAlias)->(DBSkip())
          Loop
          
      EndIf
       
        _nValor:=0
        _nVlrMix:=0
        If Len(_aSetores) > 1
           For S := 1 to Len(_aSetores)                       
		    // Total do setor dividido pelo total dos setores multiplicado pela diferenca = Total do setor com a diferenca 
		       _nVlrMix:=0
               _aSetores[S,3]:= _aSetores[S][2] / _nTotal  * SD3->D3_QUANT
               If MV_PAR06 = 1//Sem frete
                  _nVlrMix:= Posicione("ZL2",1,SD3->D3_FILIAL+_aSetores[S,1],"ZL2_ULMISF")
               EndIf
               If _nVlrMix <= 0//Se For zero é a linha que foi gravada antes de existir o campo
                  _nVlrMix:= Posicione("ZL2",1,SD3->D3_FILIAL+_aSetores[S,1],"ZL2_ULTMIX")
               EndIf
               _nValor  += (_nVlrMix * _aSetores[S,3])                          
	       Next                    
        Else
           If MV_PAR06 = 1
              _nVlrMix:= Posicione("ZL2",1, SD3->D3_FILIAL + _cSetorPA , "ZL2_ULMISF")
           EndIf
           If _nVlrMix <= 0//Se For zero é a linha que foi gravada antes de existir o campo
              _nVlrMix:= Posicione("ZL2",1, SD3->D3_FILIAL + _cSetorPA , "ZL2_ULTMIX")
           EndIf
           _nValor := (_nVlrMix * SD3->D3_QUANT)
        EndIf			

    EndIf

	If _nValor > 0//Recepcoes do SQ

	   If Round(SD3->D3_CUSTO1,2) # Round(_nValor,2)
          If MV_PAR04 = 1
             SD3->(RecLock( "SD3" , .F. )) 
             SD3->D3_CUSTO1 := _nValor
             SD3->D3_CUSTO3 := xMoeda(SD3->D3_CUSTO1,1,3,DATE()) 
             If Empty(SD3->D3_L_SETOR) .And. !Empty(_cSetorPA)
                SD3->D3_L_SETOR:=_cSetorPA
             EndIf
             SD3->(MSUnLock())  
          EndIf
          _nAcertos++
          _aLog[Len(_aLog),1]     +=" Recalculado"//Alterado
          _aLog[Len(_aLog),6]     :=_cSetores
          _aLog[Len(_aLog),nPosCA]:=TRANSF(_nValor,_cPicCus)//AllTrim(TRANSF(SD3->D3_CUSTO1,_cPicCus))
       Else
          _aLog[Len(_aLog),1]     +=" Sem Alteracao"
       EndIf
           
    ElseIf !Empty(SD3->D3_L_SETOR) //Recepcao manual
       _nVlrMix:=0
       If MV_PAR06 = 1
          _nVlrMix:= Posicione("ZL2",1, SD3->D3_FILIAL + SD3->D3_L_SETOR , "ZL2_ULMISF")
       EndIf
       If _nVlrMix <= 0//Se For zero é a linha que foi gravada antes de existir o campo
          _nVlrMix:= Posicione("ZL2",1, SD3->D3_FILIAL + SD3->D3_L_SETOR , "ZL2_ULTMIX")
       EndIf
       _nValor:=SD3->D3_QUANT * _nVlrMix

	   If ZLD->( DBSeek(SD3->D3_FILIAL+AVKEY(SD3->D3_L_ORIG,"ZLD_TICKET")+SD3->D3_L_SETOR) )
          _aLog[Len(_aLog),3]:=DToC(ZLD->ZLD_DTCOLE)//Data de coleta do ZLD
	   EndIf

	   If Round(SD3->D3_CUSTO1,2) # Round(_nValor,2)
          If MV_PAR04 = 1
             SD3->(RecLock( "SD3" , .F. ))
             SD3->D3_CUSTO1 := _nValor
             SD3->D3_CUSTO3 := xMoeda(SD3->D3_CUSTO1,1,3,DATE()) 
             SD3->(MSUnLock())
          EndIf
          _nAcertos++
          _aLog[Len(_aLog),1]     :="[Manual Recalculado]"//Alterado
          _aLog[Len(_aLog),nPosCA]:=TRANSF(_nValor,_cPicCus)//AllTrim(TRANSF(SD3->D3_CUSTO1,_cPicCus))
       Else
          _aLog[Len(_aLog),1]     :="[Manual Sem Alteracao]"
       EndIf  

    EndIf

    If Empty(SD3->D3_L_SETOR) .And. Empty(_cSetorPA)
       _aLog[Len(_aLog),1]:="[Sem Setor]"
    EndIf
       
    (_cAlias)->(DBSkip())
		
EndDo

If !Empty(_aLog)

   _aLog := aSort(_aLog,,,{|x,y| x[2]+DToS(CTOD(x[3]))+x[4]+x[5] < y[2]+DToS(CTOD(y[3]))+y[4]+y[5] })//Ordena por Filial + Data + Viagem + Setor 

   aAdd( _aLog , {"Total",""            ,DToC(DATE()),AllTrim(Str(_nAcertos,10)),'Acertos',"","","","",DToC(DATE())} )

   _cTitulo:='LOG DE PROCESSAMENTO - ACERTO DO CUSTO DO ESTOQUE'

   If MV_PAR05 = 1
   
      _aCabecalho := {} // Array com o cabeçalho das colunas do relatório. 
      // Alinhamento( 1-Left,2-Center,3-Right )
      // Formatação( 1-General,2-Number,3-Monetário,4-DateTime )
      //          Titulo das Colunas  ,Alinhamento ,Formatação, Totaliza?
      aAdd(_aCabecalho,{'Status'            ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{'Filial'            ,2           ,1         ,.F.}) 
      aAdd(_aCabecalho,{'Data Coleta'       ,2           ,4         ,.F.}) 
      aAdd(_aCabecalho,{'Ticket'            ,2           ,1         ,.F.}) 
      aAdd(_aCabecalho,{'Setor Anterior'    ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{'Setores Atualizado',1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{'Quantidade'        ,3           ,2         ,.F.}) 
      aAdd(_aCabecalho,{'Custo Anterior'    ,3           ,3         ,.F.}) 
      aAdd(_aCabecalho,{'Custo Recalculado' ,3           ,3         ,.F.}) 
      aAdd(_aCabecalho,{'Data Estoque'      ,2           ,4         ,.F.}) 

      _cDir := GetTempPath()  // Diretório de Geração das planilhas.
      _cArq := "ACERTO_ESTOQUE_"+DToS(Date())+"_"+StrTran(Time(),":","")+".xml"  // Nome da planilha a ser gerada.   

      U_ITGEREXCEL(_cArq,_cDir,_cTitulo,"Relatorio",_aCabecalho,_aLog ,.F.)

      MsgInfo("Arquivo Gerado: "+_cDir+_cArq)
	  _lsai := .F.

   Else

      _cArq := 'MFIS001_'+ StrTran( Time() , ':' , '' ) + DToS( Date() ) + RetCodUsr() +'.csv'

      U_ITGERARQ( _cTitulo , {'Status','Filial','Data Coleta','Ticket','Setor Anterior','Setores Atualizado','Quantidade','Custo Anterior','Custo Recalculado','Data Estoque'} , _aLog )

      MsgInfo("Arquivo Gerado no diretorio selecionado: "+_cArq)
	  _lsai := .F.

   EndIf
   //ITListBox( _cTitAux                                            , _aHeader                                                                                  , _aCols,_lMaxSiz,_nTipo,_cMsgTop , _lSelUnc , _aSizes              , _nCampo ) 
//   U_ITListBox( 'Log de Processamento - Acerto de custo do Estoque' , {'Status','Filial','Data Emissao','Ticket','Setor Anterior','Setor Atualizado','Quantidade','Custo Anterior','Custo Recalculado'} , _aLog , .T.    , 1    ,         ,          ,;
//                                                                      { 20     , 10     , 30           , 35     , 50             , 90               , 40         , 50             , 50                } )
		
Else

   MsgInfo("Nao foram encontro registros para essas selecoes.")
	_lsai := .F.

EndIf

//==============================================================================
// Grava log de Processamento de recálculo de custo de entrada do leite próprio
//============================================================================== 
U_ITLOGACS('MEST012')

Return .T. 

/*
===============================================================================================================================
Programa----------: MEST012Calc
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/07/2017
Descrição---------: Carrega variaveis para o recalculo do leite 
Parametros--------: _cAlias
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function MEST012Calc(_cAlias)

_cSetores:=""
_aLog[Len(_aLog),1]:=If(_cAlias="ZLD","[COM Efetivacao]","[SEM Efetivacao]")
_aLog[Len(_aLog),3]:=DToC(If(_cAlias="ZLD",(_cAlias)->ZLD_DTCOLE,(_cAlias)->ZLJ_DTIVIA))

While (_cAlias)->( !Eof() ) .And. SD3->D3_FILIAL+AllTrim(SD3->D3_L_ORIG) == If(_cAlias="ZLD", ZLD->ZLD_FILIAL+ZLD->ZLD_TICKET , ZLJ->ZLJ_FILIAL+ZLJ->ZLJ_VIAGEM )
	
	_nTotal += If(_cAlias="ZLD", ZLD->ZLD_QTDBOM , ZLJ->ZLJ_VOLUME)  
	
	_nk := aScan( _aSetores,{|x| x[1] == If(_cAlias="ZLD",ZLD->ZLD_SETOR,ZLJ->ZLJ_SETOR )} )
	
	If _nk > 0
		
		_aSetores[_nk][2] +=  If(_cAlias="ZLD", ZLD->ZLD_QTDBOM , ZLJ->ZLJ_VOLUME)
		
	Else
		
		aAdd(_aSetores, { If(_cAlias="ZLD",ZLD->ZLD_SETOR,ZLJ->ZLJ_SETOR ), If(_cAlias="ZLD", ZLD->ZLD_QTDBOM , ZLJ->ZLJ_VOLUME),0})
		
		If Len(_aSetores) = 1
			_cSetorPA:=If(_cAlias="ZLD",ZLD->ZLD_SETOR,ZLJ->ZLJ_SETOR )
		EndIf
		
		_cSetores+=If(_cAlias="ZLD",ZLD->ZLD_SETOR,ZLJ->ZLJ_SETOR )+" "
		
	EndIf

	(_cAlias)->( DBSkip() )
			
EndDo

Return .T.
