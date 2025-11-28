/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |05/07/2024| Chamado 47548. Ajuste para a gravação orreta do campo CDA_NUMITE.
Igor Melgaço  |14/08/2025| Chamado 50763. Ajustes para exclusão de lançamentos que tiveram notas excluidas.
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
Igor Melgaço  |26/09/2025| Chamado 52045. Ajustes para nova regra de apuração da IN1298.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MFIS004
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 04/01/2017
Descrição---------: Rotina para reprocessamento CDA 1298
Parametros--------: Nenhum                               
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIS004

Local _aSays		:= {} As Array
Local _aButtons		:= {} As Array
Local _cPerg		:= "MFIS004" As Character
Local _lExec		:= .T. As Logical
Local _nOpca		:= 0 As Numeric

Private _lCda1298	:= SuperGetMV("IT_CDA1298",.F.,.F.) As Logical
Private _cCaj1298	:= SuperGetMV("IT_CAJ1298",.F.,"") As Character
Private _cInf1298	:= SuperGetMV("IT_INF1298",.F.,"") As Character
Private _nRed1298 := SuperGetMV("IT_RED1298",.F.,0) As Numeric
Private _nAlq1298	:= 0 As Numeric
Private _cAlq1298	:= SuperGetMV("IT_ALQ1298",.F.,"12") As Character

If !_lCda1298
   MsgStop("Não é permitida a execução desta rotina nesta filial. Solicite a ativação desta filial para a execução desta.","MFI00401")
   Return .F.
EndIf

Pergunte( _cPerg , .F. )

aAdd( _aSays , OemToAnsi( " Este programa tem como objetivo alimentar a tabela CDA com as operações"	) )
aAdd( _aSays , OemToAnsi( " cujo a Italac assume o papel de substituto tributário nas operações "	) )
aAdd( _aSays , OemToAnsi( " interestaduais de saída referentes a IN1298."	) )

aAdd( _aButtons , { 05 , .T. , {| | Pergunte( _cPerg )			} } )
aAdd( _aButtons , { 01 , .T. , {|o| _nOpca := 1 , o:oWnd:End()	} } )
aAdd( _aButtons , { 02 , .T. , {|o| _nOpca := 0 , o:oWnd:End()	} } )

FormBatch( "MFIS004" , _aSays , _aButtons ,, 200 , 500 )
 
If _nOpca == 1

   If MV_PAR01 > MV_PAR02
      MsgStop("Datas início e fim para reprocessamento da CDA não são válidas! A data de início deve ser menor ou igual à data fim.","MFIS00402")
      Return  .F.
   EndIf
   
   If _lExec .And. MsgYesNo( 'Confirma execução ?' , 'MFIS00403' )
      If MV_PAR11 == 2 
         Processa( {|| U_MFIS004I() } , 'Reprocessamento CDA 1298'			, 'Aguarde...' )
      Else
         Processa( {|| U_MFIS004C() } , 'Reprocessamento CDA 1298'			, 'Aguarde...' )
      EndIf
   EndIf

EndIf

Return

/*
===============================================================================================================================
Programa----------: MFIS004I 
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 04/01/2017
Descrição---------: Função do reprocessamento CDA 1298          
Parametros--------: Nenhum                               
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIS004I

Local _cQryDad	:= "" As Character
Local _nI		:= 0 As Numeric
Local _cSeq     := StrZero(1,Len(CDA->CDA_SEQ)) As Character
Local _cSeqSD2  := AVKEY(StrZero(1,Len(SD2->D2_ITEM)),"CDA_NUMITE") As Character
Local _nJ As Numeric
Local _nCDAValor As Numeric
Local _nValRed As Numeric
Local _lArrayUFAliq As Logical
Local _cAlias := GetNextAlias() As Character
Local nTotal := 0 As Numeric

_cQryDad := "SELECT F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_EMISSAO, F2_ESPECIE, F2_I_FRET, F2_I_CTRA, F2_I_LTRA, F2_EST, F2_TIPO "
_cQryDad += "FROM " + RetSqlName("SF2") + " "
_cQryDad += "WHERE F2_FILIAL = '" + xFilial("SF2") + "' "
_cQryDad += "  AND F2_EMISSAO BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "' "
_cQryDad += "  AND F2_DOC BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' "
_cQryDad += "  AND F2_SERIE BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR06 + "' "
_cQryDad += "  AND F2_CLIENTE BETWEEN '" + MV_PAR07 + "' AND '" + MV_PAR09 + "' "
_cQryDad += "  AND F2_LOJA BETWEEN '" + MV_PAR08 + "' AND '" + MV_PAR10 + "' "
_cQryDad += "  AND D_E_L_E_T_ = ' '"

MPSysOpenQuery( _cQryDad,_cAlias )

DBSelectArea(_cAlias)
nTotal := 0
COUNT To nTotal

(_cAlias)->(DBGoTop())

SA2->(DBSetOrder(1))
CDA->(DBSetOrder(1))//CDA_FILIAL+CDA_TPMOVI+CDA_ESPECI  +CDA_FORMUL+ CDA_NUMERO      +CDA_SERIE        +CDA_CLIFOR         +CDA_LOJA       +CDA_NUMITE+CDA_SEQ+  CDA_CODLAN+CDA_CALPRO

_lArrayUFAliq := .T.
If _cAlq1298 == "12" // Siguinifica que o parâmetro com as Strings com estados e aliquota para filial não existe. 
   _nAlq1298 := 0    // E a função SuperGetMV retornou valor Default = "12".
   _lArrayUFAliq := .F.
Else
   _aUFAliq := U_MFIS004E(_cAlq1298) // Retorna um array para a filial logada, formado por {{"Estado","aliquota"},{"Estado","aliquota"},...}
EndIf

If (_cAlias)->(!Eof())
   ProcRegua(nTotal)

   While !((_cAlias)->(Eof()))
      _nI := _nI + 1
      IncProc( 'Processando Registro: ['+ StrZero( _nI , 6 ) +'] de ['+ StrZero( nTotal , 6 ) +']' )

      SA2->(DBSeek(xFilial("SA2") + (_cAlias)->F2_I_CTRA + (_cAlias)->F2_I_LTRA))
         
      If _lArrayUFAliq 
         _nJ := aScan(_aUFAliq, {|x| x[1] == (_cAlias)->F2_EST})
         If _nJ > 0
            _cAlq1298 := _aUFAliq[_nJ,2]
            _nAlq1298 := Val(_cAlq1298)
         Else
            _nAlq1298 := 0
         EndIf 
      EndIf 

      If ((_cAlias)->F2_FILIAL $ "01,02,06,08,09,0A,0B" .And. SA2->A2_I_CLASS $ "A,T,G,C" .And. SA2->A2_I_I1298 <> 'L' .And. SA2->A2_I_I1298 <> 'S' .And. !Empty((_cAlias)->F2_I_FRET) .And. SM0->M0_ESTENT <> SA2->A2_EST);
            .Or. ((_cAlias)->F2_FILIAL $ "01,02,06,08,09,0A,0B" .And. SA2->A2_I_CLASS $ "A,T,G,C" .And. SA2->A2_I_I1298 <> 'L' .And. SA2->A2_I_I1298 <> 'S' .And. !Empty((_cAlias)->F2_I_FRET) .And. SM0->M0_ESTENT = SA2->A2_EST  .And. SM0->M0_ESTENT <> (_cAlias)->F2_EST) .Or. ((_cAlias)->F2_FILIAL $ "94" .And. SA2->A2_I_CLASS $ "A,T,G,C" .And. SA2->A2_I_I1298 == 'S' .And. !Empty((_cAlias)->F2_I_FRET) .And. SM0->M0_ESTENT <> SA2->A2_EST);
            .Or. ((_cAlias)->F2_FILIAL $ "20,23,24,25" .And. SA2->A2_I_CLASS $ "A,T,G,C" .And. !Empty((_cAlias)->F2_I_FRET) .And.  (_cAlias)->F2_EST <> SM0->M0_ESTENT .And. SM0->M0_ESTENT <> SA2->A2_EST);							 
            .Or. ((_cAlias)->F2_FILIAL $ "40,04" .And. SA2->A2_I_CLASS $ "A,T,G,C" .And. !Empty((_cAlias)->F2_I_FRET) .And. SM0->M0_ESTENT <> SA2->A2_EST)	

         If CDA->(DBSeek((_cAlias)->F2_FILIAL + "S" + (_cAlias)->F2_ESPECIE + "S" + (_cAlias)->F2_DOC + (_cAlias)->F2_SERIE + (_cAlias)->F2_CLIENTE + (_cAlias)->F2_LOJA + _cSeqSD2 + _cSeq + _cCaj1298))
            CDA->(RecLock("CDA",.F.))
            CDA->(DBDelete())
            CDA->(MSUnLock())
         EndIf

         _nCDAValor := (_cAlias)->F2_I_FRET * (_nAlq1298 / 100)   // 1000 * 10 /100 = 100  
         
         If _nRed1298 > 0
            _nValRed   := _nCDAValor * _nRed1298 / 100         // 100 * 20 / 100 = 20
            _nCDAValor := _nCDAValor - _nValRed                // 100 - 20 = 80 
         EndIf 

         If Empty(SA2->A2_I_F1298) .Or. (_cAlias)->F2_EMISSAO > DToS(SA2->A2_I_F1298)
            CDA->(RecLock("CDA",.T.))
            CDA->CDA_FILIAL	:= (_cAlias)->F2_FILIAL
            CDA->CDA_TPMOVI	:= "S"
            CDA->CDA_ESPECI	:= (_cAlias)->F2_ESPECIE
            CDA->CDA_FORMUL	:= "S"
            CDA->CDA_NUMERO	:= (_cAlias)->F2_DOC
            CDA->CDA_SERIE	:= (_cAlias)->F2_SERIE
            CDA->CDA_CLIFOR	:= (_cAlias)->F2_CLIENTE
            CDA->CDA_LOJA	:= (_cAlias)->F2_LOJA
            CDA->CDA_NUMITE	:= _cSeqSD2
            CDA->CDA_SEQ	:= _cSeq
            CDA->CDA_CODLAN	:= _cCaj1298
            CDA->CDA_CALPRO	:= 	"1"
            CDA->CDA_BASE	:= (_cAlias)->F2_I_FRET
            CDA->CDA_ALIQ	:= _nAlq1298
            CDA->CDA_VALOR	:= _nCDAValor // TRBDAD->F2_I_FRET * (_nAlq1298 / 100)
            CDA->CDA_TPREG	:= ""
            CDA->CDA_CODOLD	:= ""
            CDA->CDA_IFCOMP := _cInf1298
            CDA->CDA_TPLANC	:= "2"
            CDA->CDA_VL197	:= ""
            CDA->CDA_CLANC	:= ""
            CDA->CDA_SDOC   := (_cAlias)->F2_SERIE
            CDA->CDA_ORIGEM := '1'
            CDA->CDA_TPNOTA := (_cAlias)->F2_TIPO
            CDA->(MSUnLock())
         EndIf
      EndIf

      (_cAlias)->(DBSkip())
   End
Else
   Aviso( 'MFIS00404' , 'Não foi retornado nenhum dado para sua consulta!' , {'Fechar'} )
EndIf

(_cAlias)->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa----------: MFIS004N
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 04/01/2017
Descrição---------: Função do reprocessamento CDA 1298, chamada do ponto de entrada M460FIM          
Parametros--------: Nenhum                               
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIS004N

Local _aSalvArea := FWGetArea() As Array
Local _cCaj1298	:= SuperGetMV("IT_CAJ1298",.F.,"") As Character
Local _cInf1298	:= SuperGetMV("IT_INF1298",.F.,"") As Character
Local _nAlq1298	As Numeric
Local _cSeq     := StrZero(1,Len(CDA->CDA_SEQ)) As Character
Local _cSeqSD2  := AVKEY(StrZero(1,Len(SD2->D2_ITEM)),"CDA_NUMITE") As Character
Local _cAlq1298 := SuperGetMV("IT_ALQ1298",.F.,"12") As Character
Local _nJ As Numeric
Local _nCDAValor As Numeric
Local _nValRed As Numeric
Local _nRed1298 := SuperGetMV("IT_RED1298",.F.,0) As Numeric

SA2->(DBSetOrder(1))
SA2->(DBSeek(xFilial("SA2") + SF2->F2_I_CTRA + SF2->F2_I_LTRA))
If _cAlq1298 == "12"
   _nAlq1298 := 0
Else
   _aUFAliq := U_MFIS004E(_cAlq1298)
EndIf

If (SF2->F2_FILIAL $ "01,02,06,08,09,0A,0B" .And. SA2->A2_I_CLASS $ "A,T,G,C" .And. SA2->A2_I_I1298 <> 'L' .And. SA2->A2_I_I1298 <> 'S' .And. !Empty(SF2->F2_I_FRET) .And. SM0->M0_ESTENT <> SA2->A2_EST);
   .Or. (SF2->F2_FILIAL $ "01,02,06,08,09,0A,0B" .And. SA2->A2_I_CLASS $ "A,T,G,C" .And. SA2->A2_I_I1298 <> 'L' .And. SA2->A2_I_I1298 <> 'S' .And. !Empty(SF2->F2_I_FRET) .And. SM0->M0_ESTENT = SA2->A2_EST  .And. SM0->M0_ESTENT <> SF2->F2_EST);
   .Or. (SF2->F2_FILIAL $ "20,23,24,25" .And. SA2->A2_I_CLASS $ "A,T,G,C" .And. !Empty(SF2->F2_I_FRET) .And.  SF2->F2_EST <> SM0->M0_ESTENT .And. SM0->M0_ESTENT <> SA2->A2_EST);							 
   .Or. (SF2->F2_FILIAL $ "40,04" .And. SA2->A2_I_CLASS $ "A,T,G,C" .And. !Empty(SF2->F2_I_FRET) .And. SM0->M0_ESTENT <> SA2->A2_EST)	
   
   If _cAlq1298 <> "12"
      _nJ := aScan(_aUFAliq, {|x| x[1] == SF2->F2_EST})
      If _nJ > 0
         _cAlq1298 := _aUFAliq[_nJ,2]
         _nAlq1298 := Val(_cAlq1298)
      Else
         _nAlq1298 := 0
      EndIf 
   EndIf 

   CDA->(DBSetOrder(1))//CDA_FILIAL+CDA_TPMOVI+CDA_ESPECI+CDA_FORMUL+CDA_NUMERO+CDA_SERIE      +CDA_CLIFOR        +CDA_LOJA+CDA_NUMITE+CDA_SEQ+CDA_CODLAN+CDA_CALPRO
   If CDA->(DBSeek(SF2->F2_FILIAL + "S" + SF2->F2_ESPECIE + "S" + SF2->F2_DOC + SF2->F2_SERIE + SF2->F2_CLIENTE + SF2->F2_LOJA + _cSeqSD2 + _cSeq + _cCaj1298 ))
      CDA->(RecLock("CDA",.F.))
      CDA->(DBDelete())
      CDA->(MSUnLock())
   EndIf

   _nCDAValor := SF2->F2_I_FRET * (_nAlq1298 / 100)   // 1000 * 10 /100 = 100  
            
   If _nRed1298 > 0
      _nValRed   := _nCDAValor * _nRed1298 / 100         // 100 * 20 / 100 = 20
      _nCDAValor := _nCDAValor - _nValRed                // 100 - 20 = 80 
   EndIf 

   CDA->(RecLock("CDA",.T.))
   CDA->CDA_FILIAL	:= SF2->F2_FILIAL
   CDA->CDA_TPMOVI	:= "S"
   CDA->CDA_ESPECI	:= SF2->F2_ESPECIE
   CDA->CDA_FORMUL	:= "S"
   CDA->CDA_NUMERO	:= SF2->F2_DOC
   CDA->CDA_SERIE	:= SF2->F2_SERIE
   CDA->CDA_CLIFOR	:= SF2->F2_CLIENTE
   CDA->CDA_LOJA	:= SF2->F2_LOJA
   CDA->CDA_NUMITE	:= _cSeqSD2
   CDA->CDA_SEQ	:= _cSeq
   CDA->CDA_CODLAN	:= _cCaj1298
   CDA->CDA_CALPRO	:= 	"1"
   CDA->CDA_BASE	:= SF2->F2_I_FRET
   CDA->CDA_ALIQ	:= _nAlq1298
   CDA->CDA_VALOR	:= _nCDAValor // SF2->F2_I_FRET * (_nAlq1298 / 100)
   CDA->CDA_TPREG	:= ""
   CDA->CDA_CODOLD	:= ""
   CDA->CDA_IFCOMP := _cInf1298
   CDA->CDA_TPLANC	:= "2"
   CDA->CDA_VL197	:= ""
   CDA->CDA_CLANC	:= ""
   CDA->CDA_SDOC   := SF2->F2_SERIE
   CDA->CDA_ORIGEM := '1'
   CDA->CDA_TPNOTA := SF2->F2_TIPO
   CDA->(MSUnLock())

EndIf

FWRestArea(_aSalvArea)

Return .T.

/*
===============================================================================================================================
Programa----------: MFIS004E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/07/2021
Descrição---------: Recebe um parâmetro e retorna um Array com siglas de estados e suas respectiva alicotas.        
Parametros--------: _cSiglaAliq = string com siglas dos estados e suas respectivas aliquotas.                            
Retorno-----------: _aRet = Array com as siglas dos estado e suas repectivas aliquotas.
===============================================================================================================================
*/
User Function MFIS004E(_cSiglaAliq As Character)

Local _aUF := {} As Array
Local _nI := 0 As Numeric
Local _nJ := 0 As Numeric
Local _nX := 0 As Numeric
Local _nPosIni := 0 As Numeric
Local _aRet := {} As Array
Local _cUF := "" As Character
Local _cTaxa := "" As Character

Begin Sequence
   If Empty(_cSiglaAliq)
      Break
   EndIf 

   _aUF := {}
   aAdd(_aUF,"RO")
   aAdd(_aUF,"AC")
   aAdd(_aUF,"AM")
   aAdd(_aUF,"RR")
   aAdd(_aUF,"PA")
   aAdd(_aUF,"AP")
   aAdd(_aUF,"TO")
   aAdd(_aUF,"MA")
   aAdd(_aUF,"PI")
   aAdd(_aUF,"CE")
   aAdd(_aUF,"RN")
   aAdd(_aUF,"PB")
   aAdd(_aUF,"PE")
   aAdd(_aUF,"AL")	
   aAdd(_aUF,"MG")
   aAdd(_aUF,"ES")
   aAdd(_aUF,"RJ")
   aAdd(_aUF,"SP")
   aAdd(_aUF,"PR")
   aAdd(_aUF,"SC")
   aAdd(_aUF,"RS")
   aAdd(_aUF,"MS")
   aAdd(_aUF,"MT")
   aAdd(_aUF,"GO")
   aAdd(_aUF,"DF")
   aAdd(_aUF,"SE")
   aAdd(_aUF,"BA")
   aAdd(_aUF,"EX")
   
   For _nI := 1 To Len(_aUF)
      _cUF   := _aUF[_nI]
      _cTaxa :=  0

      _nPosIni := AT(_cUF, _cSiglaAliq)
      If _nPosIni == 0
         Loop
      EndIf 

      _nPosIni := _nPosIni + 2 
      _nX := 0

      For _nJ := _nPosIni To Len(_cSiglaAliq)
         If SubStr(_cSiglaAliq,_nJ,1) $ "0123456789"
            _nX += 1 
         Else
            Exit
         EndIf 
      Next 

      If _nX > 0
         _cTaxa := SubStr(_cSiglaAliq,_nPosIni,_nX)
      Else
         Loop   
      EndIf 

      aAdd(_aRet,{_cUF,_cTaxa})

   Next

End Sequence

Return _aRet

/*
===============================================================================================================================
Programa----------: MFIS004C
Autor-------------: Igor Melgaço
Data da Criacao---: 15/07/2025
Descrição---------: Recebe um parâmetro e retorna um Array com siglas de estados e suas respectiva alicotas.        
Parametros--------:                            
Retorno-----------: _aRet = Array com as siglas dos estado e suas repectivas aliquotas.
===============================================================================================================================
*/
User Function MFIS004C

Local _cQryDad	:= "" As Character
Local _nI		:= 0 As Numeric
Local _nJ      := 0 As Numeric
Local _lArrayUFAliq := .F. As Logical
Local _cAlias := GetNextAlias() As Character
Local nTotal := 0 As Numeric

_cQryDad := "SELECT F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_EMISSAO, F2_ESPECIE, F2_I_FRET, F2_I_CTRA, F2_I_LTRA, F2_EST, F2_TIPO, CDA_FILIAL, CDA_NUMERO, CDA_SERIE, CDA_CLIFOR, CDA_LOJA, CDA.R_E_C_N_O_ AS RECNO "
_cQryDad += "FROM " + RetSqlName("CDA") + " CDA "
_cQryDad += "   LEFT JOIN " + RetSqlName("SF2") + " SF2 ON CDA.CDA_FILIAL = SF2.F2_FILIAL AND CDA.CDA_TPMOVI = 'S' AND CDA.CDA_ESPECI = SF2.F2_ESPECIE AND CDA.CDA_NUMERO = SF2.F2_DOC AND CDA.CDA_SERIE = SF2.F2_SERIE AND CDA.CDA_CLIFOR = SF2.F2_CLIENTE AND CDA.CDA_LOJA = SF2.F2_LOJA "
_cQryDad += "WHERE F2_FILIAL = '" + xFilial("SF2") + "' "
_cQryDad += "  AND F2_EMISSAO BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "' "
_cQryDad += "  AND F2_DOC BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' "
_cQryDad += "  AND F2_SERIE BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR06 + "' "
_cQryDad += "  AND F2_CLIENTE BETWEEN '" + MV_PAR07 + "' AND '" + MV_PAR09 + "' "
_cQryDad += "  AND F2_LOJA BETWEEN '" + MV_PAR08 + "' AND '" + MV_PAR10 + "' "
_cQryDad += "  AND SF2.D_E_L_E_T_ = '*' "

MPSysOpenQuery( _cQryDad,_cAlias )

DBSelectArea(_cAlias)
nTotal := 0
COUNT To nTotal

SA2->(DBSetOrder(1))
CDA->(DBSetOrder(1))//CDA_FILIAL+CDA_TPMOVI+CDA_ESPECI  +CDA_FORMUL+ CDA_NUMERO      +CDA_SERIE        +CDA_CLIFOR         +CDA_LOJA       +CDA_NUMITE+CDA_SEQ+  CDA_CODLAN+CDA_CALPRO

_lArrayUFAliq := .T.
If _cAlq1298 == "12" // Siguinifica que o parâmetro com as Strings com estados e aliquota para filial não existe. 
   _nAlq1298 := 0    // E a função SuperGetMV retornou valor Default = "12".
   _lArrayUFAliq := .F.
Else
   _aUFAliq := U_MFIS004E(_cAlq1298) // Retorna um array para a filial logada, formado por {{"Estado","aliquota"},{"Estado","aliquota"},...}
EndIf

(_cAlias)->(DBGoTop())

If (_cAlias)->(!Eof())
   ProcRegua(nTotal)
   While (_cAlias)->(!Eof())
      _nI++
      IncProc( 'Processando Registro: ['+ StrZero( _nI , 6 ) +'] de ['+ StrZero( nTotal , 6 ) +']' )
      SA2->(DBSeek(xFilial("SA2") + (_cAlias)->F2_I_CTRA + (_cAlias)->F2_I_LTRA))
         
      If _lArrayUFAliq 
         _nJ := aScan(_aUFAliq, {|x| x[1] == (_cAlias)->F2_EST})
         If _nJ > 0
            _cAlq1298 := _aUFAliq[_nJ,2]
            _nAlq1298 := Val(_cAlq1298)
         Else
            _nAlq1298 := 0
         EndIf 
      EndIf 

      If ((_cAlias)->F2_FILIAL $ "01,02,06,08,09,0A,0B" .And. SA2->A2_I_CLASS $ "A,T,G,C" .And. SA2->A2_I_I1298 <> 'L' .And. SA2->A2_I_I1298 <> 'S' .And. !Empty((_cAlias)->F2_I_FRET) .And. SM0->M0_ESTENT <> SA2->A2_EST);
            .Or. ((_cAlias)->F2_FILIAL $ "01,02,06,08,09,0A,0B" .And. SA2->A2_I_CLASS $ "A,T,G,C" .And. SA2->A2_I_I1298 <> 'L' .And. SA2->A2_I_I1298 <> 'S' .And. !Empty((_cAlias)->F2_I_FRET) .And. SM0->M0_ESTENT = SA2->A2_EST  .And. SM0->M0_ESTENT <> (_cAlias)->F2_EST);
            .Or. ((_cAlias)->F2_FILIAL $ "20,23,24,25" .And. SA2->A2_I_CLASS $ "A,T,G,C" .And. !Empty((_cAlias)->F2_I_FRET) .And.  (_cAlias)->F2_EST <> SM0->M0_ESTENT .And. SM0->M0_ESTENT <> SA2->A2_EST);							 
            .Or. ((_cAlias)->F2_FILIAL $ "40,04" .And. SA2->A2_I_CLASS $ "A,T,G,C" .And. !Empty((_cAlias)->F2_I_FRET) .And. SM0->M0_ESTENT <> SA2->A2_EST)	
      
         CDA->(DBGoTo((_cAlias)->RECNO))
         CDA->(RecLock("CDA",.F.))
         CDA->(DBDelete())
         CDA->(MSUnLock())
      EndIf
      
      (_cAlias)->(DBSkip())
   EndDo
Else
   Aviso( 'MFIS00404' , 'Não foi retornado nenhum dado para sua consulta!' , {'Fechar'} )
EndIf

(_cAlias)->(DBCloseArea())

Return
