/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "report.ch"

/*
===============================================================================================================================
Programa----------: MCOM016
Autor-------------: Julio de Paula Paz
Data da Criacao---: 12/04/2021
Descrição---------: Lista Notas Fiscais de Entrada Vinculada com Campo Específico do XML da nota fiscal. Chamado 36143.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM016()
Local _cPerg := "MCOM016" 
Local _lRet := .F.

Private _aDados := {}
Private _lGravaDados := .F.
Private _aOrder := {"Data de Digitação"}
Private _oReport := Nil
Private _oSect1_A := Nil 

Begin Sequence

   If ! Pergunte(_cPerg,.T.)
      Break
   EndIf
   
   If MV_PAR03 == 1
      If U_ITMsg("Confirma a atualização das tabelas de dados?","Atenção","Os campos 'F1_TPFRETE' e 'DS_TPFRETE' serão atualizados conforme regras estabelecidas." , ,2, 2) 
         _lGravaDados := .T.
      ElseIf MV_PAR04 == 1 
         U_ITMsg("Apenas o relatório será emitido.","Atenção", ,2)
      EndIf
   EndIf

   If MV_PAR03 == 2 .And. MV_PAR04 == 2
      U_ITMsg("Rotina finalizada pelo usuário.","Atenção","O usuário selecionou as opções 'Não gerar relatório e Não atualizar tabelas." ,2)
      Break 
   EndIf 

   //======================================================
   // Efetua a Leitura e Montagem dos dados
   //======================================================
   FWMsgRun( ,{|_oProc| _lRet := U_MCOM016D(_oProc) } , 'Aguarde...' , 'Efetuando Leitura dos dados...' )

   If ! _lRet 
      If MV_PAR04 == 1 
         U_ITMsg("Não foram encontrados dados para serem listados.","Atenção",,1)
      Else 
         U_ITMsg("Não foram encontrados dados para atualização das tabelas de dados.","Atenção",,1)
      EndIf 

      Break
   EndIf

   If MV_PAR04 == 1 
      //======================================================
      // Efetua a Leitura e Montagem dos dados
      //======================================================
      _oReport := MCOM016R() 
      _oReport:PrintDialog()

   EndIf 

End Sequence

U_ITMsg("Processamento finalizado.","Atenção",,2)

If Select("TRBTOMA") > 0
	TRBTOMA->(DBCloseArea())
EndIf

Return 

/*
===============================================================================================================================
Programa----------: MCOM016D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 12/04/2021
Descrição---------: Rotina de leitura e montagem dos dados.
Parametros--------: _oProc = Objeto da regua de processamento
Retorno-----------: _lRet = .T. = há dados para emissão da listagem.
                            .F. = não há dados para emissão da listagem.
===============================================================================================================================
*/
User Function MCOM016D(_oProc)

Local _cQry, _nTotRegs, _nI 
Local _lRet := .F.
Local _cChave 
Local _oXml, _cError := "", _cWarning := ""
Local _cTagDest, _cCGCDes, _lToma3 := .F.
Local _cObs := "", _lErroCKO
Local _cArquiv := "", _cCNPJRem := ""
Local _cXMLRet, _lToma4 := .F.
Local _nRecSF1, _nRecSDS
Local _aStruct, _oTemp 
Local _nTotGrv

Begin Sequence
   _aStruct := {}
   If MV_PAR04 == 1
      aAdd(_aStruct,{"F1_FILIAL" , "C", 2, 0}) 
      aAdd(_aStruct,{"F1_DOC"    , "C",GetSx3Cache("F1_DOC"    , "X3_TAMANHO"), 0})     
      aAdd(_aStruct,{"F1_SERIE"  , "C",GetSx3Cache("F1_SERIE"  , "X3_TAMANHO"), 0})  
      aAdd(_aStruct,{"F1_FORNECE", "C",GetSx3Cache("F1_FORNECE", "X3_TAMANHO"), 0})
      aAdd(_aStruct,{"F1_LOJA"   , "C",GetSx3Cache("F1_LOJA"   , "X3_TAMANHO"), 0})   
      aAdd(_aStruct,{"A2_NOME"   , "C",GetSx3Cache("A2_NOME"   , "X3_TAMANHO"), 0}) 
      aAdd(_aStruct,{"F1_EMISSAO", "D", 8, 0})
      aAdd(_aStruct,{"F1_DTDIGIT", "D", 8, 0})
      aAdd(_aStruct,{"F1_EST"    , "C", 2, 0})    
      aAdd(_aStruct,{"F1_TPFRETE", "C", 1, 0}) //C=CIF;F=FOB;T=Por conta terceiros;R=Por conta remetente;D=Por conta destinatário;S=Sem frete
      aAdd(_aStruct,{"TOMA"      , "C", 1, 0})
      aAdd(_aStruct,{"TOMA3"     , "C", 3, 0})
      aAdd(_aStruct,{"TOMA4"     , "C", 3, 0})
      aAdd(_aStruct,{"CNPJDES"   , "C",14, 0})
      aAdd(_aStruct,{"CNPJITALAC", "C",14, 0})
      aAdd(_aStruct,{"CNPJREM"   , "C",14, 0})
      aAdd(_aStruct,{"F1_CHVNFE" , "C",GetSx3Cache("F1_CHVNFE" , "X3_TAMANHO") , 0})
      aAdd(_aStruct,{"CKO_ARQUIV", "C",GetSx3Cache("CKO_ARQUIV", "X3_TAMANHO") , 0})
      aAdd(_aStruct,{"OBSERVACAO", "M",10, 0})
      aAdd(_aStruct,{"ARQXML"    , "M",10, 0})
      aAdd(_aStruct,{"RECSF1"    , "N",10, 0})
      aAdd(_aStruct,{"RECSDS"    , "N",10, 0})
   Else
      aAdd(_aStruct,{"F1_DTDIGIT", "D", 8, 0})
      aAdd(_aStruct,{"TOMA"      , "C", 1, 0})
      aAdd(_aStruct,{"RECSF1"    , "N",10, 0})
      aAdd(_aStruct,{"RECSDS"    , "N",10, 0})
   EndIf 
 
   _oTemp := FWTemporaryTable():New( "TRBTOMA",  _aStruct) 
   _oTemp:AddIndex( "01", {"F1_DTDIGIT"} )
   _oTemp:Create()

   _oProc:cCaption := ("Efetuando Leitura dos dados...")
   ProcessMessages()

   _cQry := " SELECT SF1.R_E_C_N_O_ AS NRRECNO "
   _cQry += " FROM " + RetSqlName("SF1") + " SF1 "
   _cQry += " WHERE SF1.D_E_L_E_T_ = ' ' AND F1_ESPECIE = 'CTE' "
  
   If ! Empty(MV_PAR01)
      _cQry += " AND F1_DTDIGIT >= '" + DToS(MV_PAR01) + "' "
   EndIf

   If ! Empty(MV_PAR02)
      _cQry += " AND F1_DTDIGIT <= '" + DToS(MV_PAR02) + "' "
   EndIf

   If Select("QRYSF1") > 0
	  QRYSF1->(DBCloseArea())
   EndIf

   _cQry := ChangeQuery(_cQry)
   MPSysOpenQuery(_cQry,"QRYSF1")
   DBSelectArea("QRYSF1")
   Count To _nTotRegs

   If _nTotRegs == 0
      _lRet := .F.
      Break
   EndIf
 
   CKO->(DBSetOrder(1)) 
   SDS->(DBSetOrder(2)) //DS_FILIAL+DS_CHAVENF

   QRYSF1->(DBGoTop())
   
   _nTotGrv := 0

   _nI := 1 
   While ! QRYSF1->(Eof())
      _oProc:cCaption := ("Processando os dados ["+ AllTrim(Str(_nI,10)) +"/"+ AllTrim(Str(_nTotRegs,10)) + "]...")
      ProcessMessages()
      
      _nI += 1
      _cObs := ""
      _lErroCKO := .F.
      _cArquiv := ""

      _nRecSF1 := 0
      _nRecSDS := 0

      SF1->(DBGoTo(QRYSF1->NRRECNO))
      _nRecSF1 := QRYSF1->NRRECNO
      
      If SDS->(MsSeek(SF1->F1_FILIAL+SF1->F1_CHVNFE))
         _nRecSDS := SDS->(Recno())
      EndIf
      
      If Upper(SubStr(SF1->F1_CHVNFE,1,3)) == "CTE"
         _cChave := "214" + AllTrim(SubStr(SF1->F1_CHVNFE,4,Len(SF1->F1_CHVNFE)))+".xml"
      Else
         _cChave := "214" + AllTrim(SF1->F1_CHVNFE)+".xml"
      EndIf

      If CKO->(MsSeek(_cChave))

         _cXMLRet := CKO->CKO_XMLRET
         _cXMLRet := AllTrim(StrTran(_cXMLRet,"???","")) 

         _oXml := ""
         If ! Empty(_cXMLRet)
            _oXml := XmlParser(_cXMLRet, "_" , @_cError , @_cWarning )
         EndIf

         _cToma := ""
         _cTagDest    := ""
	      _cCGCDes	    := ""
         _lToma3      := .F.
         _lToma4      := .F.
         _cCNPJItalac := ""
         _cArquiv     := CKO->CKO_ARQUIV
         _cCNPJRem    := ""

         If ValType(_oXml) == "O"
            If ValType( XmlChildEx( _oXML:_CTEProc:_CTE:_Infcte:_ide, "_TOMA4" ) )  <> "U" 
	            _cTagDest	:= If( ValType( XmlChildEx(	_oXML:_CTEProc:_CTE:_Infcte:_ide:_Toma4	, "_CNPJ" ) ) == "O" , "_CNPJ" , "_CPF" )
	            _cCGCDes	:= AllTrim( XmlChildEx(_oXML:_CTEProc:_CTE:_Infcte:_ide:_Toma4	, _cTagDest ):Text )
               _cToma   := AllTrim( _oXML:_CTEProc:_CTE:_Infcte:_ide:_Toma4:_TOMA:Text)
               _lToma4  := .T.
               _cCNPJItalac := U_MCOM016C(_cCGCDes)
            ElseIf ValType( XmlChildEx( _oXML:_CTEProc:_CTE:_Infcte:_ide, "_TOMA3" ) )  <> "U" 
               _cToma   := AllTrim( _oXML:_CTEProc:_CTE:_Infcte:_ide:_Toma3:_TOMA:Text)
               _lToma3  := .T.
               _cCNPJItalac := ""
               _cCGCDes := ""
            ElseIf ValType( XmlChildEx( _oXML:_CTEProc:_CTE:_Infcte:_ide, "_TOMA04" ) )  <> "U" 
	            _cTagDest	:= If( ValType( XmlChildEx(	_oXML:_CTEProc:_CTE:_Infcte:_ide:_Toma04	, "_CNPJ" ) ) == "O" , "_CNPJ" , "_CPF" )
	            _cCGCDes	:= AllTrim( XmlChildEx(_oXML:_CTEProc:_CTE:_Infcte:_ide:_Toma04	, _cTagDest ):Text )
               _cToma   := AllTrim( _oXML:_CTEProc:_CTE:_Infcte:_ide:_Toma04:_TOMA:Text)
               _lToma4  := .T.
               _cCNPJItalac := U_MCOM016C(_cCGCDes)
            ElseIf ValType( XmlChildEx( _oXML:_CTEProc:_CTE:_Infcte:_ide, "_TOMA03" ) )  <> "U" 
               _cToma   := AllTrim( _oXML:_CTEProc:_CTE:_Infcte:_ide:_Toma03:_TOMA:Text)
               _lToma3  := .T.
               _cCNPJItalac := ""
               _cCGCDes := ""
            EndIf

            If ValType( XmlChildEx( _oXML:_CTEProc:_CTE:_Infcte:_rem, "_CNPJ" ) )  <> "U" 
               _cCNPJRem := AllTrim( _oXML:_CTEProc:_CTE:_Infcte:_rem:_CNPJ:Text)  
            ElseIf ValType( XmlChildEx( _oXML:_CTEProc:_CTE:_Infcte:_rem, "_CPF" ) )  <> "U" 
               _cCNPJRem := AllTrim( _oXML:_CTEProc:_CTE:_Infcte:_rem:_CPF:Text)         
            EndIf  
            
            If MV_PAR04 == 1 
               TRBTOMA->(RecLock("TRBTOMA", .T.))
               TRBTOMA->F1_FILIAL := SF1->F1_FILIAL
               TRBTOMA->F1_DOC := SF1->F1_DOC
               TRBTOMA->F1_SERIE := SF1->F1_SERIE
               TRBTOMA->F1_FORNECE := SF1->F1_FORNECE
               TRBTOMA->F1_LOJA := SF1->F1_LOJA
               TRBTOMA->A2_NOME := Posicione("SA2",1,xFilial("SA2")+SF1->F1_FORNECE+SF1->F1_LOJA,"A2_NOME")
               TRBTOMA->F1_EMISSAO := SF1->F1_EMISSAO
               TRBTOMA->F1_DTDIGIT := SF1->F1_DTDIGIT
               TRBTOMA->F1_EST := SF1->F1_EST
               TRBTOMA->F1_TPFRETE :=  SF1->F1_TPFRETE
               TRBTOMA->TOMA := _cToma
               TRBTOMA->TOMA3 := If(_lToma3,"Sim","Não")
               TRBTOMA->TOMA4 := If(_lToma4,"Sim","Não")
               TRBTOMA->CNPJDES := _cCGCDes
               TRBTOMA->CNPJITALAC := _cCNPJItalac
               TRBTOMA->CNPJREM := _cCNPJRem
               TRBTOMA->F1_CHVNFE := SF1->F1_CHVNFE
               TRBTOMA->CKO_ARQUIV := CKO->CKO_ARQUIV 
               TRBTOMA->OBSERVACAO := _cObs
               TRBTOMA->ARQXML := ""
               TRBTOMA->RECSF1 := _nRecSF1
               TRBTOMA->RECSDS := _nRecSDS
               TRBTOMA->(MSUnLock())
               _nTotGrv += 1                            
            Else 
               TRBTOMA->(RecLock("TRBTOMA", .T.))
               TRBTOMA->F1_DTDIGIT := SF1->F1_DTDIGIT
               TRBTOMA->TOMA   := _cToma
               TRBTOMA->RECSF1 := _nRecSF1
               TRBTOMA->RECSDS := _nRecSDS
               TRBTOMA->(MSUnLock()) 

               _nTotGrv += 1

            EndIf 
            _lRet := .T.   
         Else
            _cObs := "Erro na leitura do XML: " + AllTrim(StrTran(_cError,CRLF," "))   
            _lErroCKO := .T.    
         EndIf               
      Else 
         _cObs := "Não foi possível localizar chave na tabela CKO." 
         _lErroCKO := .T.
      EndIf

      If _lErroCKO .And. MV_PAR04 == 1 
         TRBTOMA->(RecLock("TRBTOMA", .T.))
         TRBTOMA->F1_FILIAL := SF1->F1_FILIAL
         TRBTOMA->F1_DOC := SF1->F1_DOC
         TRBTOMA->F1_SERIE := SF1->F1_SERIE
         TRBTOMA->F1_FORNECE := SF1->F1_FORNECE
         TRBTOMA->F1_LOJA := F1_LOJA
         TRBTOMA->A2_NOME := Posicione("SA2",1,xFilial("SA2")+SF1->F1_FORNECE+SF1->F1_LOJA,"A2_NOME")
         TRBTOMA->F1_EMISSAO := SF1->F1_EMISSAO
         TRBTOMA->F1_DTDIGIT := SF1->F1_DTDIGIT
         TRBTOMA->F1_EST     := SF1->F1_EST
         TRBTOMA->F1_TPFRETE :=  SF1->F1_TPFRETE
         TRBTOMA->TOMA       := ""
         TRBTOMA->TOMA3      := ""
         TRBTOMA->TOMA4      := ""
         TRBTOMA->CNPJDES    := ""
         TRBTOMA->CNPJITALAC := ""
         TRBTOMA->CNPJREM    := ""
         TRBTOMA->F1_CHVNFE  := SF1->F1_CHVNFE
         TRBTOMA->CKO_ARQUIV := CKO->CKO_ARQUIV 
         TRBTOMA->OBSERVACAO := _cObs
         TRBTOMA->ARQXML     := ""
         TRBTOMA->RECSF1     := 0
         TRBTOMA->RECSDS     := 0
         TRBTOMA->(MSUnLock())
         _nTotGrv += 1
      EndIf 

      QRYSF1->(DBSkip())
      
      _oXml := Nil 
      DelClassIntf()

   EndDo
   
   TRBTOMA->(DBGoTop())

   If _lGravaDados
      
      _nI := 1

      While ! TRBTOMA->(Eof())   
         _oProc:cCaption := ("Gravando tabelas de dados ["+ AllTrim(Str(_nI,10)) +"/"+ AllTrim(Str(_nTotGrv,10)) + "]...")
         ProcessMessages()

         _cToma   := TRBTOMA->TOMA  
         _nRecSF1 := TRBTOMA->RECSF1 
         _nRecSDS := TRBTOMA->RECSDS 

         If _nRecSF1 > 0
            SF1->(DBGoTo(_nRecSF1))
         EndIf

         If _nRecSDS > 0 
            SDS->(DBGoTo(_nRecSDS)) 
         EndIf
          
         If AllTrim(_cToma) == "0" .Or. AllTrim(_cToma) == "1" 
            If _nRecSF1 > 0
               If SF1->F1_TPFRETE == "F" .And. U_MCOM016P(SF1->F1_FILIAL,SF1->F1_DOC,SF1->F1_SERIE,SF1->F1_FORNECE,SF1->F1_LOJA,"0","SD1")
                  SF1->(RecLock("SF1",.F.))
                  SF1->F1_TPFRETE := "C" 
                  SF1->(MSUnLock())
               EndIf
            EndIf 
                
            If _nRecSDS > 0 
               If SDS->DS_TPFRETE == "F"  .And. U_MCOM016P(SF1->F1_FILIAL,SF1->F1_DOC,SF1->F1_SERIE,SF1->F1_FORNECE,SF1->F1_LOJA,"0","SDT")
                  SDS->(RecLock("SDS",.F.))
                  SDS->DS_TPFRETE := "C"
                  SDS->(MSUnLock())
               EndIf 
            EndIf
          
         ElseIf AllTrim(_cToma) == "4"
            If _nRecSF1 > 0
               If SF1->F1_TPFRETE == "F" .And. U_MCOM016P(SF1->F1_FILIAL,SF1->F1_DOC,SF1->F1_SERIE,SF1->F1_FORNECE,SF1->F1_LOJA,"4","SD1")
                  SF1->(RecLock("SF1",.F.))
                  SF1->F1_TPFRETE := "T" 
                  SF1->(MSUnLock())
               EndIf
            EndIf 
               
            If _nRecSDS > 0 
               If SDS->DS_TPFRETE == "F" .And. U_MCOM016P(SF1->F1_FILIAL,SF1->F1_DOC,SF1->F1_SERIE,SF1->F1_FORNECE,SF1->F1_LOJA,"4","SDT")
                  SDS->(RecLock("SDS",.F.))
                  SDS->DS_TPFRETE := "T"
                  SDS->(MSUnLock())
               EndIf  
            EndIf 
         EndIf
  
         TRBTOMA->(DBSkip())
         _nI += 1
      EndDo
   EndIf 

End Sequence

If Select("QRYSF1") > 0
	QRYSF1->(DBCloseArea())
EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: MCOM016C
Autor-----------: Julio de Paula Paz
Data da Criacao-: 19/03/2021
Descrição-------: Verifica se o CNPJ passado por parâmetro é da Italac.
Parametros------: _cCnpj = Cnpj a ser pesquisado
Retorno---------: _cRet = "SIM" / "NAO"
===============================================================================================================================
*/
User Function MCOM016C(_cCGCDes)

Local _cRet := ""
Local _cQry

Begin Sequence 

   _cQry := " SELECT Count(*) AS NRREGS "
   _cQry += " FROM " + RetSqlName("ZZM") + " ZZM "
   _cQry += " WHERE ZZM.D_E_L_E_T_ = ' ' AND ZZM_CGC = '" + _cCGCDes + "' "

   If Select("QRYZZM") > 0
	  QRYZZM->(DBCloseArea())
   EndIf

   _cQry := ChangeQuery(_cQry)
   MPSysOpenQuery(_cQry,"QRYZZM")
   DBSelectArea("QRYZZM")
   If QRYZZM->(Eof()) .Or. QRYZZM->(Bof()) 
      _cRet := "NAO"
      Break 
   EndIf 
   
   If QRYZZM->NRREGS > 0
      _cRet := "SIM"
   Else
      _cRet := "NAO"
   EndIf 
   
End Sequence 

If Select("QRYZZM") > 0
   QRYZZM->(DBCloseArea())
EndIf

Return _cRet 

/*
===============================================================================================================================
Programa--------: MCOM016P
Autor-----------: Julio de Paula Paz
Data da Criacao-: 20/04/2021
Descrição-------: Verifica se existe produtos do toma na tabela SD1
Parametros------: _cCodFilial  = Filial
                  _cNrNf       = Numero da Nota de entrada
                  _cSerieNf    = Serie da nota de entrada
                  _cFornecedor = Codigo do fornecedor 
                  _cLojaFor    = Loja do Fornecedor.
                  _cNrToma     = Numero do toma
                  _cTabPesq    = Tabela a ser pesquisada SD1 ou SDT
Retorno---------: _lRet = .T. / .F. 
===============================================================================================================================
*/
User Function MCOM016P(_cCodFilial,_cNrNf,_cSerieNf,_cFornecedor,_cLojaFor,_cNrToma, _cTabPesq)

Local _lRet := .F.             
Local _cPrdToma0 := SuperGetMV("IT_PRTOMA0",.F.,"10000000005;10000000014;") 
Local _cPrdToma4 := SuperGetMV("IT_PRTOMA4",.F.,"10000000005;10000000006;10000000014;") 
Local _cProdutos := ""

Begin Sequence 
   If _cNrToma == "0" .Or. _cNrToma == "1"
      _cProdutos := _cPrdToma0
   Else 
      _cProdutos := _cPrdToma4 
   EndIf

   If _cTabPesq == "SD1"
      SD1->(DBSetOrder(1)) // D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
      SD1->(MsSeek(_cCodFilial + _cNrNf + _cSerieNf + _cFornecedor + _cLojaFor))

      While ! SD1->(Eof()) .And. SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) == (_cCodFilial + _cNrNf + _cSerieNf + _cFornecedor + _cLojaFor)
         If AllTrim(SD1->D1_COD) $ _cProdutos
            _lRet := .T.
            Break 
         EndIf 

         SD1->(DBSkip())
      EndDo
   Else 
      SDT->(DBSetOrder(3)) // DT_FILIAL+DT_FORNEC+DT_LOJA+DT_DOC+DT_SERIE+DT_COD 
      SDT->(MsSeek(_cCodFilial + _cFornecedor + _cLojaFor + _cNrNf + _cSerieNf ))

      While ! SDT->(Eof()) .And. SDT->(DT_FILIAL+DT_FORNEC+DT_LOJA+DT_DOC+DT_SERIE) == (_cCodFilial + _cFornecedor + _cLojaFor + _cNrNf + _cSerieNf )
         If AllTrim(SDT->DT_COD) $ _cProdutos
            _lRet := .T.
            Break 
         EndIf 

         SDT->(DBSkip())
      EndDo
   EndIf

End Sequence

Return _lRet 

/*
===============================================================================================================================
Programa----------:  MCOM016R
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/06/2021
Descrição---------: Gera o relatório em Excel e na impressora.
Parametros--------: _oProc ==  Objeto da regura de processos.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM016R(_oProc)


Begin Sequence	
  
   _oReport := TReport():New("MCOM016R", "Dados Nota Fiscal de Entrada X Conteúdo do XML da NF" ,, {|_oReport| MCOM016I(_oReport,_oSect1_A)})
   _oReport:SetLandscape()    
   _oReport:SetTotalInLine(.F.)

   _oSect1_A := TRSection():New(_oReport, "Dados Nota Fiscal de Entrada X Conteúdo do XML da NF" , {"TRBTOMA"},_aOrder , .F., .T.)
   TRCell():New(_oSect1_A,"F1_FILIAL"	,"TRBTOMA","Filial","@D",06) 
   TRCell():New(_oSect1_A,"F1_DOC"	   ,"TRBTOMA","Nota Fiscal","@!",11)
   TRCell():New(_oSect1_A,"F1_SERIE"	,"TRBTOMA","Serie NF","@!",08)
   TRCell():New(_oSect1_A,"F1_FORNECE"	,"TRBTOMA","Fornecedor","@!",10)
   TRCell():New(_oSect1_A,"F1_LOJA"	   ,"TRBTOMA","Loja For.","@!",09)
   TRCell():New(_oSect1_A,"A2_NOME"   	,"TRBTOMA","Razão Social","@!",30)
   TRCell():New(_oSect1_A,"F1_EMISSAO"	,"TRBTOMA","Data de Emissão","@D",15)
   TRCell():New(_oSect1_A,"F1_DTDIGIT"	,"TRBTOMA","Data de Digitação","@D",15)
   TRCell():New(_oSect1_A,"F1_EST"   	,"TRBTOMA","UF","@D",2)
   TRCell():New(_oSect1_A,"F1_TPFRETE"	,"TRBTOMA","Tipo de Frete","@D",15)
   TRCell():New(_oSect1_A,"TOMA"	      ,"TRBTOMA","Toma","@!",6)
   TRCell():New(_oSect1_A,"TOMA3"	   ,"TRBTOMA","É Toma 3","@!",8)
   TRCell():New(_oSect1_A,"TOMA4"	   ,"TRBTOMA","É Toma 4","@!",8)
   TRCell():New(_oSect1_A,"CNPJDES"	   ,"TRBTOMA","CNPJ","@D",15)
   TRCell():New(_oSect1_A,"CNPJITALAC"	,"TRBTOMA","É CNPJ da Italac","@D",16)
   TRCell():New(_oSect1_A,"CNPJREM"	   ,"TRBTOMA","CNPJ/CPF Remetente","@D",18)
   TRCell():New(_oSect1_A,"F1_CHVNFE"	,"TRBTOMA","Chave NFE (SF1)",,30) 
   TRCell():New(_oSect1_A,"CKO_ARQUIV"	,"TRBTOMA","Chave/Arquivo (CKO)",,30)
   TRCell():New(_oSect1_A,"OBSERVACAO"	,"TRBTOMA","Observação","@!",200)
  
End Sequence
					
Return(_oReport)

/*
===============================================================================================================================
Programa----------:  MCOM016I
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/06/2021
Descrição---------: Grava os dados de impressão do relatório.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM016I(_oReport,_oSect1_A)

Begin Sequence
   TRBTOMA->(DBGoTop())

   //====================================================================================================
   // Inicializando a impressão
   //====================================================================================================
   _oSect1_A:Enable() 		 
	_oSect1_A:Init()

	While ! TRBTOMA->(Eof())

      If _oReport:Cancel()
		   Exit
      EndIf
		
      _oReport:IncMeter()   
	          
      //====================================================================================================
      // Imprimindo...
      //====================================================================================================		 
      _oSect1_A:Cell("F1_FILIAL"):SetValue(TRBTOMA->F1_FILIAL)
      _oSect1_A:Cell("F1_DOC"):SetValue(TRBTOMA->F1_DOC)
      _oSect1_A:Cell("F1_SERIE"):SetValue(TRBTOMA->F1_SERIE)
      _oSect1_A:Cell("F1_FORNECE"):SetValue(TRBTOMA->F1_FORNECE)
      _oSect1_A:Cell("F1_LOJA"):SetValue(TRBTOMA->F1_LOJA)
      _oSect1_A:Cell("A2_NOME"):SetValue(TRBTOMA->A2_NOME)
      _oSect1_A:Cell("F1_EMISSAO"):SetValue(TRBTOMA->F1_EMISSAO)
      _oSect1_A:Cell("F1_DTDIGIT"):SetValue(TRBTOMA->F1_DTDIGIT)
      _oSect1_A:Cell("F1_EST"):SetValue(TRBTOMA->F1_EST)
      _oSect1_A:Cell("F1_TPFRETE"):SetValue(TRBTOMA->F1_TPFRETE)
      _oSect1_A:Cell("TOMA"):SetValue(TRBTOMA->TOMA)
      _oSect1_A:Cell("TOMA3"):SetValue(TRBTOMA->TOMA3)
      _oSect1_A:Cell("TOMA4"):SetValue(TRBTOMA->TOMA4)
      _oSect1_A:Cell("CNPJDES"):SetValue(TRBTOMA->CNPJDES)
      _oSect1_A:Cell("CNPJITALAC"):SetValue(TRBTOMA->CNPJITALAC)
      _oSect1_A:Cell("CNPJREM"):SetValue(TRBTOMA->CNPJREM)
      _oSect1_A:Cell("F1_CHVNFE"):SetValue(TRBTOMA->F1_CHVNFE)
      _oSect1_A:Cell("CKO_ARQUIV"):SetValue(TRBTOMA->CKO_ARQUIV)
      _oSect1_A:Cell("OBSERVACAO"):SetValue(TRBTOMA->OBSERVACAO)
      
      _oSect1_A:PrintLine()

      TRBTOMA->(DBSkip()) 
   EndDo   

End Sequence

Return 
