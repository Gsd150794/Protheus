/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |21/08/2018| Chamado 30301. Ajustes p/ parametros novos IT_FAFRVEN/IT_VOLUAGU/IT_OUTROMO
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
Alex Wallauer |24/09/2025| Chamado 52151. Alteração da leitura dos parametros do ZP1 para o SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MEST017
Autor-------------: Alex Wallauer
Data da Criacao---: 23/12/2018
Descrição---------: Rotina de atualização de parâmetros de EMCARGOS PARA FOLHA DE PAGAMENTO - CUSTO GERENCIAL - Chamado 27368
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function MEST017

Local _cPict := "@E 999.999"           as Char
Local _cPict2:= "@E 9.9999999"         as Char
Local _cPict5:= "@E 999.99999"         as Char
Local _cPictI:= "@E 999,999,999.99999" as Char
Local _cPictC:= "@!"                   as Char

//VERIfICA PERMISSÕES DE ACESSO
Private _lRet1 := .T. As Logical
Private _lRet3 := .T. As Logical
Private _lRet5 := .T. As Logical
Private _lRetA := .T. As Logical
Private _lRetB := .T. As Logical
Private _lRetB2:= .T. As Logical
Private _lRetC := .T. As Logical
Private _lRetC2:= .T. As Logical
Private _lRetD := .T. As Logical
Private _lRetE := .T. As Logical
Private _lRetF := .T. As Logical
Private _lRetF2:= .T. As Logical
Private _lRetG := .T. As Logical
Private _lRetH := .T. As Logical
Private _lRetI := .T. As Logical
Private _lRetJ := .T. As Logical

Private _oDlg				// Dialog Principal
Private _lContinua := .T.
oMainWnd:ReadClientCoords()//So precisa declarar uma fez para o Programa todo

//PASTA 1 "EMCARGOS P/ FOLHA DE PAGAMENTO E FRETE"                              123456789012345 - Inicie na posicao 15 a descrição do SX6 
Private _aPerg1 := {"Ferias (%) ?"                                            ,"IT_FERIAS   - Digite o percentual de Ferias"} As Array
Private _aPerg3 := {"13 Salario (%) ?"                                        ,"IT_13SALA   - Digite o percentual de 13 Salario"} As Array
Private _aPerg5 := {"Fator Frete VEndas ?"                                    ,"IT_FAFRVEN  - Digite o Fator Frete VEndas"} As Array
//PASTA 2 "VOLUME DO LEITE"                                                     123456789012345 - Inicie na posicao 15 a descrição do SX6
Private _aPergA := {"Postos de captação ?"                                    ,"IT_POSTCAP  - InFormar nesse parametro quais são os postos de captação"} As Array
Private _aPergB := {"Produtos MP para composição do vol. ?"                   ,"IT_MPCUSTO  - InFormar produtos que irão compor o volume através das entradas do leite para quando a filial For posto de captação e quando não For posto, a soma dos produtos inFormados será através das requisições para a produção(consumo)"} As Array
Private _aPergB2:= {"Considera Desmontagens dos Produtos MP acima ?"          ,"IT_MPDESMO  - Considera Desmontagens dos Produtos MP acima"} As Array
Private _aPergC := {"Produtos PA para composição do vol. ?"                   ,"IT_PACUSTO  - A soma das produções dos PAs inFormados nesse parâmetro irão compor o volume total"} As Array
Private _aPergC2:= {"Considera Transferencias (550) dos Produtos PA acima ?"  ,"IT_PATRANS  - Considera Transferencias (550) dos Produtos PA acima"} As Array
Private _aPergD := {"Centros Custo das MPs p/ compor vol ?."                  ,"IT_MPCCUST  - Os centros de custos inFormados aqui irão filtrar a soma do volume para os produtos inFormados nesse parametro"} As Array
Private _aPergE := {"Centros Custo das PAs p/ compor vol. ?"                  ,"IT_PACCUST  - Os centros de custos inFormados aqui irão filtrar a soma do volume para os produtos inFormados nesse parametro"} As Array
Private _aPergF := {"Produtos de retorno ?"                                   ,"IT_RETCUST  - Os produtos inFormados aqui são os que tiveram retorno para os estoque através da produção"} As Array
Private _aPergF2:= {"Para compor vol. ?"                                      ,"IT_CRETCUS  - Os produtos inFormados acima serão somados ou descontados no volume total"} As Array
Private _aPergG := {"Filais para somar no volume ?"                           ,"IT_FILSOMA  - Caso o volume total seja através da soma de dados de mais de uma filial inFormar aqui quais são as filiais, caso seja somente de uma não há necessidade de preencher. O conteudo deste parametro será somente processado caso nas perguntas de execução da leitura de regras a pergunta 'Soma Litragem' estiver como 'Sim'"} As Array
Private _aPergH := {"EspecIfico RS - Taxa FUNDESA ?"                          ,"IT_TXFUNDE  - Taxa de contribuição a ser aplicada no volume compro/recebido Leite/MP, valor de contribuição para o Fundo de Desenvolvimento e Defesa Sanitária Animal do Rio Grande do Sul - FUNDESA."} As Array
Private _aPergI := {"Volume Agua ?"                                           ,"IT_VOLUAGU  - Volume da agua aplicado no total de litros leite por consumo de materia prima."} As Array
Private _aPergJ := {"Outro Mov. ?"                                            ,"IT_OUTROMO  - Outro movimento aplicado no total de litros leite por consumo de materia prima."} As Array
//                                                                              123456789012345 - Inicie na posicao 15 a descrição do SX6 

//MONTA VARIAVEIS
//PASTA 1 "EMCARGOS P/ FOLHA DE PAGAMENTO"
Private _nIT_FERIAS  := VAL(SuperGetMV("IT_FERIAS",.F.,"11.107")) As Char //OK
Private _nIT_13SALA  := VAL(SuperGetMV("IT_13SALA",.F.,"08.330")) As Char //OK
//PASTA 2 "VOLUME DO LEITE"      1234567890
Private _cIT_POSTCAPT:= SuperGetMV("IT_POSTCAP",.F.,Space(Len(SX6->X6_CONTEUD))) As Char //OK
Private _cIT_MPCUSTO := SuperGetMV("IT_MPCUSTO",.F.,Space(Len(SX6->X6_CONTEUD))) As Char //OK
Private _cIT_PACUSTO := SuperGetMV("IT_PACUSTO",.F.,Space(Len(SX6->X6_CONTEUD))) As Char //OK
Private _cIT_MPCCUST := SuperGetMV("IT_MPCCUST",.F.,Space(Len(SX6->X6_CONTEUD))) As Char //OK
Private _cIT_PACCUST := SuperGetMV("IT_PACCUST",.F.,Space(Len(SX6->X6_CONTEUD))) As Char //OK
Private _cIT_RETCUST := SuperGetMV("IT_RETCUST",.F.,Space(Len(SX6->X6_CONTEUD))) As Char //OK
Private _cIT_FILSOMA := SuperGetMV("IT_FILSOMA",.F.,Space(Len(SX6->X6_CONTEUD))) As Char //OK
Private _nIT_TXFUNDE := SuperGetMV("IT_TXFUNDE",.F.,0) As Char //OK

If  _lRet5
   _aOp5:={}
   Aadd(_aOp5,"Multiplicar")
   Aadd(_aOp5,"Dividir    ")
   _nIT_FAFRVEN := SuperGetMV("IT_FAFRVEN",.F.,"0*")
   If "*" $ _nIT_FAFRVEN
      _nIT_FAFRVEN:= VAL(_nIT_FAFRVEN)
      _cIT_FAFRVEN:= "Multiplicar"
   ElseIf "/" $ _nIT_FAFRVEN
      _nIT_FAFRVEN:= VAL(_nIT_FAFRVEN)
      _cIT_FAFRVEN:= "Dividir    "
   EndIf
EndIf

If  _lRetB2
_cIT_MPDESMON:=SuperGetMV("IT_MPDESMO",.F.,"N") 
   If VALTYPE(_cIT_MPDESMON) = "L"
      _cIT_MPDESMON:="N"
   EndIf
   If _cIT_MPDESMON = "S"
      _cIT_MPDESMON:= "Sim"
   ElseIf _cIT_MPDESMON = "A"
      _cIT_MPDESMON:= "Ambos"
   Else
      _cIT_MPDESMON:= "Nao"
   EndIf
EndIf

If _lRetC2
_cIT_PATRANS:=SuperGetMV("IT_PATRANS",.F.,"N")
   If VALTYPE(_cIT_PATRANS) = "L"
      _cIT_PATRANS:="N"
   EndIf
   If _cIT_PATRANS = "S"
      _cIT_PATRANS:= "Sim"
   ElseIf _cIT_PATRANS = "A"
      _cIT_PATRANS:= "Ambos"
   Else
      _cIT_PATRANS:= "Nao"
   EndIf
EndIf

If _lRetF2
   _aOpF2:={}
   Aadd(_aOpF2,"1-Soma DE1")
   Aadd(_aOpF2,"2-Desconta DE1")
   Aadd(_aOpF2,"3-Soma RE7")
   Aadd(_aOpF2,"4-Desconta RE7")
   Aadd(_aOpF2,"5-Soma Ambos")
   Aadd(_aOpF2,"6-Desconta Ambos")

_cIT_CRETCUST:=VAL(SuperGetMV("IT_CRETCUS",.F.,"4"))
   If _cIT_CRETCUST >  0 .AND. _cIT_CRETCUST <= Len(_aOpF2)
      _cIT_CRETCUST:= _aOpF2[_cIT_CRETCUST]
   Else
      _cIT_CRETCUST:= _aOpF2[4]
   EndIf
EndIf

If _lRetI
   _aOpI:={}
   Aadd(_aOpI,"Somar ")
   Aadd(_aOpI,"Abater")
   _nIT_VOLUAGUA:= SuperGetMV("IT_VOLUAGU",.F.,0)
   If _nIT_VOLUAGUA >= 0
      _cIT_VOLUAGUA:= "Somar "
   Else
      _nIT_VOLUAGUA:= _nIT_VOLUAGUA * -1
      _cIT_VOLUAGUA:= "Abater"
   EndIf
EndIf

If _lRetJ
   _aOpJ:={}
   Aadd(_aOpJ,"Somar ")
   Aadd(_aOpJ,"Abater")
   _nIT_OUTROMOV:= SuperGetMV("IT_OUTROMO",.F.,0)
   If _nIT_outromov >= 0
      _cIT_OUTROMOV:= "Somar "
   Else
      _nIT_outromov:= _nIT_outromov * -1
      _cIT_OUTROMOV:= "Abater"
   EndIf
EndIf

_cIT_POSTCAPT:= _cIT_POSTCAPT+Space(Len(SX6->X6_CONTEUD)-Len(_cIT_POSTCAPT))
_cIT_MPCUSTO := _cIT_MPCUSTO +Space(Len(SX6->X6_CONTEUD)-Len(_cIT_MPCUSTO))
_cIT_PACUSTO := _cIT_PACUSTO +Space(Len(SX6->X6_CONTEUD)-Len(_cIT_PACUSTO))
_cIT_MPCCUST := _cIT_MPCCUST +Space(Len(SX6->X6_CONTEUD)-Len(_cIT_MPCCUST))
_cIT_PACCUST := _cIT_PACCUST +Space(Len(SX6->X6_CONTEUD)-Len(_cIT_PACCUST))
_cIT_RETCUST := _cIT_RETCUST +Space(Len(SX6->X6_CONTEUD)-Len(_cIT_RETCUST))
_cIT_FILSOMA := _cIT_FILSOMA +Space(Len(SX6->X6_CONTEUD)-Len(_cIT_FILSOMA))

nposv := 005
nposh := 010
navav := 040
navah := 230

nQuebra:=007//ESSA É QUANTIDADE DE GET DE CADA LADO Ex. se For 10 no total coloca 5 se 12 coloca 6 e assim por diante

//Monta array de posições
_ni  := 0
_nqt := 15
apos := {}
nQuebra--//Tem que tirar para dar certo
Do while _ni <= _nqt
   Aadd(apos,{nposv + ( iIf(_ni > nQuebra, _ni - (nQuebra+1), _ni) * navav ), (iIf(_ni > nQuebra, 1,0) * navah) + nposh})
   _ni++
Enddo

_nInicio   :=  MEST017T(015)

_nColFolder:=  MEST017T(500)//LARGURA
_nLinFolder:=  MEST017T(275)//ALTURA

_nColPanel :=  MEST017T(500)//LARGURA
_nLinPanel :=  MEST017T(255)//ALTURA

_lContinua := .T.

Do while _lContinua

   _ni := 1
   _lContinua :=.T.

   Define Msdialog _oDlg Title "CUSTO GERENCIAL - PARAMETROS" From MEST017T(000),MEST017T(000) To MEST017T(585),MEST017T(1000) Pixel


   @ MEST017T(2),MEST017T(150) Button "Atualizar Parametros" Size MEST017T(080),MEST017T(013) Pixel OF _oDlg Action(MsgRun("Processando alteracao, aguarde...",,{|| _lContinua := MEST017C(_oDlg)}))

   @ MEST017T(2),MEST017T(250) Button "SAIR" Size MEST017T(080),MEST017T(013) Pixel OF _oDlg Action(_oDlg:End())

   _aFoders:={"EMCARGOS P/ FOLHA DE PAGAMENTO E FRETE","VOLUME DO LEITE"}

   oTFolder1:= TFolder():New( _nInicio,1,_aFoders,,_oDlg,,,,.T., , _nColFolder,_nLinFolder )
      //     TScrollBox():New( [ oWnd ]            ,[ nTop ],[ nLeft],[ nHeight ] , [ nWidth],lVertical,lHorizontal,lBorder)
   oPanel	 := TScrollBox():New(oTFolder1:aDialogs[1], 1      ,1       ,_nLinPanel,_nColPanel-5,.T.      ,.T.        ,.T.)

   If _ni <= Len(apos) .and. _lRet1

      @ MEST017T(apos[_ni][1]),MEST017T(apos[_ni][2]) TO MEST017T(apos[_ni][1]+35),MEST017T(apos[_ni][2]+216)  Pixel OF oPanel

      @ MEST017T(apos[_ni][1]+14),MEST017T(apos[_ni][2] +4) Say _aPerg1[1] Size MEST017T(150),MEST017T(015) Pixel OF oPanel

      @ MEST017T(apos[_ni][1]+13),MEST017T(apos[_ni][2] + 80  ) MSGET _oIT_FERIAS VAR _nIT_FERIAS Size MEST017T(050),MEST017T(009) Picture _cPict Pixel OF oPanel VALID POSITIVO()

      _oIT_FERIAS:bHelp:={|| ShowHelpCpo("_nIT_FERIAS",{_aPerg1[2]},2,{"Deve ser Positivo"},2)}
      _ni++

   EndIf

   If _ni <= Len(apos) .and. _lRet3

      @ MEST017T(apos[_ni][1]),MEST017T(apos[_ni][2]) TO MEST017T(apos[_ni][1]+35),MEST017T(apos[_ni][2]+216)  Pixel OF oPanel

      @ MEST017T(apos[_ni][1]+14),MEST017T(apos[_ni][2] +4) Say  _aPerg3[1] Size MEST017T(150),MEST017T(015) Pixel OF oPanel

      @ MEST017T(apos[_ni][1]+13),MEST017T(apos[_ni][2] + 80) MsGet _oIT_13SALA VAR _nIT_13SALA Size MEST017T(050),MEST017T(009) Picture _cPict Pixel OF oPanel VALID POSITIVO()

      _oIT_13SALA:bHelp:={|| ShowHelpCpo("_nIT_13SALA",{_aPerg3[2]},2,{"Deve ser Positivo"},2)}

      _ni++

   EndIf

   If _ni <= Len(apos) .and. _lRet5

      @ MEST017T(apos[_ni][1]),MEST017T(apos[_ni][2]) TO MEST017T(apos[_ni][1]+35),MEST017T(apos[_ni][2]+216)  Pixel OF oPanel

      @ MEST017T(apos[_ni][1]+14),MEST017T(apos[_ni][2] +4) Say _aPerg5[1] Size MEST017T(150),MEST017T(015) Pixel OF oPanel

      @ MEST017T(apos[_ni][1]+13),MEST017T(apos[_ni][2]+80) MsGet    _oIT_FAFRVEN  VAR _nIT_FAFRVEN SIZE MEST017T(050),MEST017T(009) PICTURE _cPict5 Pixel OF oPanel VALID POSITIVO()
      _oIT_FAFRVEN:bHelp:={|| ShowHelpCpo("_nIT_FAFRVEN",{_aPerg5[2]},2,{"Deve ser Positivo"},2)}

      @ MEST017T(apos[_ni][1]+13),MEST017T(apos[_ni][2]+145) COMBOBOX _ocIT_FAFRVEN VAR _cIT_FAFRVEN SIZE MEST017T(045),MEST017T(010)  Pixel OF oPanel ITEMS _aOp5
      _ocIT_FAFRVEN:bHelp:={|| ShowHelpCpo("_cIT_FAFRVEN",{_aPergF2[2]},2,{'Escolha uma das opcoes'},2)}

      _ni++

   EndIf

///////////////// *****************  PASTA 2 - VOLUME DO LEITE COLUNA 1 ***************** //////////////////////

   //       TScrollBox():New( [ oWnd ]            ,[ nTop ],[ nLeft],[ nHeight ] , [ nWidth],lVertical,lHorizontal,lBorder)
   oPanel2 := TScrollBox():New(oTFolder1:aDialogs[2], 1      ,1       ,_nLinPanel,_nColPanel-5,.T.      ,.T.        ,.T.)
   _ni2 := 1
   _nCol2:=105
   If _ni2 <= Len(apos) .and. _lRetA
      @ MEST017T(apos[_ni2][1]),MEST017T(apos[_ni2][2]) TO MEST017T(apos[_ni2][1]+35),MEST017T(apos[_ni2][2]+216)  Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+14),MEST017T(apos[_ni2][2] +4) Say _aPergA[1] Size MEST017T(150),MEST017T(015) Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+13),MEST017T(apos[_ni2][2] +_nCol2) MSGET _oIT_POSTCAPT VAR _cIT_POSTCAPT Size MEST017T(100),MEST017T(008) Picture _cPictC Pixel OF oPanel2
      _oIT_POSTCAPT:bHelp:={|| ShowHelpCpo("_cIT_POSTCAPT",{_aPergA[2]},2,{'Separe os codigos com ponto e virgula ";"'},2)}
      _ni2++
   EndIf

   If _ni2 <= Len(apos) .and. _lRetB
      @ MEST017T(apos[_ni2][1]),MEST017T(apos[_ni2][2]) TO MEST017T(apos[_ni2][1]+35),MEST017T(apos[_ni2][2]+216)  Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+14),MEST017T(apos[_ni2][2] +4) Say _aPergB[1] Size MEST017T(150),MEST017T(015) Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+13),MEST017T(apos[_ni2][2] +_nCol2) MSGET _oIT_MPCUSTO VAR _cIT_MPCUSTO Size MEST017T(100),MEST017T(008) Picture _cPictC Pixel OF oPanel2
      _oIT_MPCUSTO:bHelp:={|| ShowHelpCpo("_cIT_MPCUSTO",{_aPergB[2]},2,{'Separe os codigos com ponto e virgula ";"'},2)}
      _ni2++
   EndIf

   If _ni2 <= Len(apos) .and. _lRetB2
      @ MEST017T(apos[_ni2][1]),MEST017T(apos[_ni2][2]) TO MEST017T(apos[_ni2][1]+35),MEST017T(apos[_ni2][2]+216)  Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+14),MEST017T(apos[_ni2][2]+4) Say _aPergB2[1] Size MEST017T(150),MEST017T(015) Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+13),MEST017T(apos[_ni2][2]+160) COMBOBOX _oIT_MPDESMON VAR _cIT_MPDESMON Size MEST017T(040),MEST017T(010)  Pixel OF oPanel2 ITEMS {"Sim","Nao","Ambos"}
      _oIT_MPDESMON:bHelp:={|| ShowHelpCpo("_cIT_MPDESMON",{_aPergB2[2]},2,{'Escolha uma opcao Sim ou Nao ou Ambos'},2)}
      _ni2++
   EndIf

   If _ni2 <= Len(apos) .and. _lRetC
      @ MEST017T(apos[_ni2][1]),MEST017T(apos[_ni2][2]) TO MEST017T(apos[_ni2][1]+35),MEST017T(apos[_ni2][2]+216)  Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+14),MEST017T(apos[_ni2][2] +4) Say _aPergC[1] Size MEST017T(150),MEST017T(015) Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+13),MEST017T(apos[_ni2][2] +_nCol2) MSGET _oIT_PACUSTO VAR _cIT_PACUSTO Size MEST017T(100),MEST017T(008) Picture _cPictC Pixel OF oPanel2
      _oIT_PACUSTO:bHelp:={|| ShowHelpCpo("_cIT_PACUSTO",{_aPergC[2]},2,{'Separe os codigos com ponto e virgula ";"'},2)}
      _ni2++
   EndIf

   If _ni2 <= Len(apos) .and. _lRetC2
      @ MEST017T(apos[_ni2][1]),MEST017T(apos[_ni2][2]) TO MEST017T(apos[_ni2][1]+35),MEST017T(apos[_ni2][2]+216)  Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+14),MEST017T(apos[_ni2][2] +4) Say _aPergC2[1] Size MEST017T(150),MEST017T(015) Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+13),MEST017T(apos[_ni2][2] +160) COMBOBOX _oIT_PATRANS VAR _cIT_PATRANS Size MEST017T(040),MEST017T(010)  Pixel OF oPanel2 ITEMS {"Sim","Nao","Ambos"}
      _oIT_PATRANS:bHelp:={|| ShowHelpCpo("_cIT_PATRANS",{_aPergC2[2]},2,{'Escolha uma opcao Sim ou Nao ou Ambos'},2)}
      _ni2++
   EndIf

   If _ni2 <= Len(apos) .and. _lRetD
      @ MEST017T(apos[_ni2][1]),MEST017T(apos[_ni2][2]) TO MEST017T(apos[_ni2][1]+35),MEST017T(apos[_ni2][2]+216)  Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+14),MEST017T(apos[_ni2][2] +4) Say _aPergD[1] Size MEST017T(150),MEST017T(015) Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+13),MEST017T(apos[_ni2][2] +_nCol2) MSGET _oIT_MPCCUST VAR _cIT_MPCCUST Size MEST017T(100),MEST017T(008) Picture _cPictC Pixel OF oPanel2
      _oIT_MPCCUST:bHelp:={|| ShowHelpCpo("_cIT_MPCCUST",{_aPergD[2]},2,{'Separe os codigos com ponto e virgula ";"'},2)}
      _ni2++
   EndIf

   If _ni2 <= Len(apos) .and. _lRetE
      @ MEST017T(apos[_ni2][1]),MEST017T(apos[_ni2][2]) TO MEST017T(apos[_ni2][1]+35),MEST017T(apos[_ni2][2]+216)  Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+14),MEST017T(apos[_ni2][2] +4) Say _aPergE[1] Size MEST017T(150),MEST017T(015) Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+13),MEST017T(apos[_ni2][2] +_nCol2) MSGET _oIT_PACCUST VAR _cIT_PACCUST Size MEST017T(100),MEST017T(008) Picture _cPictC Pixel OF oPanel2
      _oIT_PACCUST:bHelp:={|| ShowHelpCpo("_cIT_PACCUST",{_aPergE[2]},2,{'Separe os codigos com ponto e virgula ";"'},2)}
      _ni2++
   EndIf

   ///////////////// *****************  PASTA 2 - VOLUME DO LEITE COLUNA 2 ***************** //////////////////////
   _nCol4:=100

   If _ni2 <= Len(apos) .and. _lRetF
      @ MEST017T(apos[_ni2][1]),MEST017T(apos[_ni2][2]) TO MEST017T(apos[_ni2][1]+35),MEST017T(apos[_ni2][2]+216)  Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+14),MEST017T(apos[_ni2][2] +4) Say _aPergF[1] Size MEST017T(150),MEST017T(015) Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+13),MEST017T(apos[_ni2][2] +_nCol4) MSGET _oIT_RETCUST VAR _cIT_RETCUST Size MEST017T(100),MEST017T(008)  Picture _cPictC Pixel OF oPanel2
      _oIT_RETCUST:bHelp:={|| ShowHelpCpo("_cIT_RETCUST",{_aPergF[2]},2,{'Separe os codigos com ponto e virgula ";"'},2)}
      _ni2++
   EndIf

   If _ni2 <= Len(apos) .and. _lRetF2
      @ MEST017T(apos[_ni2][1]),MEST017T(apos[_ni2][2]) TO MEST017T(apos[_ni2][1]+35),MEST017T(apos[_ni2][2]+216)  Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+14),MEST017T(apos[_ni2][2] +4) Say _aPergF2[1] Size MEST017T(150),MEST017T(015) Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+13),MEST017T(apos[_ni2][2] +_nCol4) COMBOBOX _oIT_CRETCUST VAR _cIT_CRETCUST Size MEST017T(100),MEST017T(010)  Pixel OF oPanel2 ITEMS _aOpF2
      _oIT_CRETCUST:bHelp:={|| ShowHelpCpo("_cIT_CRETCUST",{_aPergF2[2]},2,{'Escolha uma das opcoes'},2)}
      _ni2++
   EndIf

   If _ni2 <= Len(apos) .and. _lRetG
      @ MEST017T(apos[_ni2][1]),MEST017T(apos[_ni2][2]) TO MEST017T(apos[_ni2][1]+35),MEST017T(apos[_ni2][2]+216)  Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+14),MEST017T(apos[_ni2][2] +4) Say _aPergG[1] Size MEST017T(150),MEST017T(015) Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+13),MEST017T(apos[_ni2][2] +_nCol4) MSGET _oIT_FILSOMA VAR _cIT_FILSOMA Size MEST017T(100),MEST017T(008) Picture _cPictC Pixel OF oPanel2
      _oIT_FILSOMA:bHelp:={|| ShowHelpCpo("_cIT_FILSOMA",{_aPergG[2]},2,{'Separe os codigos com ponto e virgula ";"'},2)}
      _ni2++
   EndIf

   If _ni2 <= Len(apos) .and. _lRetH
      @ MEST017T(apos[_ni2][1]),MEST017T(apos[_ni2][2]) TO MEST017T(apos[_ni2][1]+35),MEST017T(apos[_ni2][2]+216)  Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+14),MEST017T(apos[_ni2][2] +4) Say _aPergH[1] Size MEST017T(150),MEST017T(015) Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+13),MEST017T(apos[_ni2][2] +_nCol4) MsGet _oIT_TXFUNDE VAR _nIT_TXFUNDE Size MEST017T(100),MEST017T(008) Picture _cPict2 Pixel OF oPanel2 VALID POSITIVO()
      _oIT_TXFUNDE:bHelp:={|| ShowHelpCpo("_nIT_TXFUNDE",{_aPergH[2]},2,{"Deve ser Positivo"},2)}
      _ni2++
   EndIf

   If _ni2 <= Len(apos) .and. _lRetI
      @ MEST017T(apos[_ni2][1]),MEST017T(apos[_ni2][2]) TO MEST017T(apos[_ni2][1]+35),MEST017T(apos[_ni2][2]+216)  Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+14),MEST017T(apos[_ni2][2] +4) Say _aPergI[1] Size MEST017T(150),MEST017T(015) Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+13),MEST017T(apos[_ni2][2]+080) MsGet    _oIT_VOLUAGUA  VAR _nIT_VOLUAGUA SIZE MEST017T(060),MEST017T(008) PICTURE _cPictI Pixel OF oPanel2 VALID POSITIVO()
      _oIT_VOLUAGUA:bHelp:={|| ShowHelpCpo("_nIT_VOLUAGUA",{_aPergI[2]},2,{"Deve ser Positivo"},2)}
      @ MEST017T(apos[_ni2][1]+13),MEST017T(apos[_ni2][2] +160) COMBOBOX _ocIT_VOLUAGUA VAR _cIT_VOLUAGUA Size MEST017T(040),MEST017T(010)  Pixel OF oPanel2 ITEMS _aOpI
      _ocIT_VOLUAGUA:bHelp:={|| ShowHelpCpo("_cIT_VOLUAGUA",{_aPergI[2]},2,{'Escolha uma opcao Somar ou Abater'},2)}
      _ni2++
   EndIf

   If _ni2 <= Len(apos) .and. _lRetJ
      @ MEST017T(apos[_ni2][1]),MEST017T(apos[_ni2][2]) TO MEST017T(apos[_ni2][1]+35),MEST017T(apos[_ni2][2]+216)  Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+14),MEST017T(apos[_ni2][2] +4) Say _aPergJ[1] Size MEST017T(150),MEST017T(015) Pixel OF oPanel2
      @ MEST017T(apos[_ni2][1]+13),MEST017T(apos[_ni2][2]+080) MsGet    _oIT_OUTROMOV VAR _nIT_outromov SIZE MEST017T(060),MEST017T(008) PICTURE _cPictI Pixel OF oPanel2 VALID POSITIVO()
      _oIT_OUTROMOV:bHelp:={|| ShowHelpCpo("_nIT_outromov",{_aPergJ[2]},2,{"Deve ser Positivo"},2)}
      @ MEST017T(apos[_ni2][1]+13),MEST017T(apos[_ni2][2] +160) COMBOBOX _ocIT_OUTROMOV VAR _cIT_OUTROMOV Size MEST017T(040),MEST017T(010) Pixel OF oPanel2 ITEMS _aOpJ
      _ocIT_OUTROMOV:bHelp:={|| ShowHelpCpo("_cIT_OUTROMOV",{_aPergJ[2]},2,{'Escolha uma opcao Somar ou Abater'},2)}
      _ni2++
   EndIf

   Activate Msdialog _oDlg Centered

   _lContinua :=.F.

Enddo

Return(.T.)

/*
===============================================================================================================================
Programa----------: MEST017C
Autor-------------: Josué Danich
Data da Criacao---: 09/01/2017
Descrição---------: Atualiza parâmetros da filial corrente
Parametros--------: _oDlg as Object
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function MEST017C(_oDlg as Object) as Logical

Local _aFiliais  := {} As Array
Local _alog      := {} As Array
Local _aVal      := {} As Array
Local _cFilAtual := cFilAnt As Char
Local V          := 0 As Numeric 
Local F          := 0 As Numeric 
Local _lAchou    := .F. As Logical
Local _lAmbTeste := !totvs.framework.environment.type.get() = '1' as Logical//1-Produção, 2-Homologação,3-Desenvolvimento
cFilAnt:=cFilAnt//por causa de tipos de variaveis

Aadd(_aVal,{"IT_FERIAS"  ,STR(_nIT_FERIAS,8,3)                                              ,_lRet1 ,_aPerg1 ,"C"})
Aadd(_aVal,{"IT_13SALA"  ,STR(_nIT_13SALA,8,3)                                              ,_lRet3 ,_aPerg3 ,"C"})
Aadd(_aVal,{"IT_FAFRVEN" ,STR(_nIT_FAFRVEN,9,5)+If(_cIT_FAFRVEN="Multiplicar","*","/")      ,_lRet5 ,_aPerg5 ,"C"})
Aadd(_aVal,{"IT_POSTCAPT",_cIT_POSTCAPT                                                     ,_lRetA ,_aPergA ,"C"})
Aadd(_aVal,{"IT_MPCUSTO" ,_cIT_MPCUSTO                                                      ,_lRetB ,_aPergB ,"C"})
Aadd(_aVal,{"IT_MPDESMON",If(_cIT_MPDESMON="Sim","S",If(_cIT_MPDESMON="Ambos","A","N"))     ,_lRetB2,_aPergB2,"C"})
Aadd(_aVal,{"IT_PACUSTO" ,_cIT_PACUSTO                                                      ,_lRetC ,_aPergC ,"C"})
Aadd(_aVal,{"IT_PATRANS" ,If(_cIT_PATRANS ="Sim","S",If(_cIT_MPDESMON="Ambos","A","N"))     ,_lRetC2,_aPergC2,"C"})
Aadd(_aVal,{"IT_MPCCUST" ,_cIT_MPCCUST                                                      ,_lRetD ,_aPergD ,"C"})
Aadd(_aVal,{"IT_PACCUST" ,_cIT_PACCUST                                                      ,_lRetE ,_aPergE ,"C"})
Aadd(_aVal,{"IT_RETCUST" ,_cIT_RETCUST                                                      ,_lRetF ,_aPergF ,"C"})
Aadd(_aVal,{"IT_CRETCUST",_cIT_CRETCUST                                                     ,_lRetF2,_aPergF2,"C"})
Aadd(_aVal,{"IT_FILSOMA" ,_cIT_FILSOMA                                                      ,_lRetG ,_aPergG ,"C"})
Aadd(_aVal,{"IT_TXFUNDES",STR(_nIT_TXFUNDE,15,8)                                            ,_lRetH ,_aPergH ,"N"})//O tipo é numerico na hora da leitura
Aadd(_aVal,{"IT_VOLUAGUA",If(_cIT_VOLUAGUA="Abater","-","")+ALLTRIM(STR(_nIT_VOLUAGUA,15,5)),_lRetI ,_aPergI ,"N"})
Aadd(_aVal,{"IT_OUTROMOV",If(_cIT_OUTROMOV="Abater","-","")+ALLTRIM(STR(_nIT_outromov,15,5)),_lRetJ ,_aPergJ ,"N"})

SX6->(Dbsetorder(1))

For V := 1 TO Len(_aVal)

   If _aVal[V,3]

      If (SX6->(DbSeek( cFilAnt + _aVal[V,1] )) .OR. SX6->(DbSeek('  '+_aVal[V,1] ) ) )

         Aadd(_alog,{"Atualizado na filial",SX6->X6_FIL,_aVal[V,1],SX6->X6_TIPO,_aVal[V,2],ALLTRIM(SX6->X6_CONTEUD),LEFT(_aVal[V,4,1],Len(_aVal[V,4,1])-1) })
         //_aVal[V,1],LEFT(_aVal[V,4,1],Len(_aVal[V,4,1])-1)+" alterado de: "+ALLTRIM(SX6->X6_CONTEUD)+" para: " + ALLTRIM(_aVal[V,2]) + " na filial: ["+If(EMPTY(SX6->X6_FIL),"Todas",SX6->X6_FIL)+"]"})

         PutMv(_aVal[V,1],If(SX6->X6_TIPO="N",VAL(_aVal[V,2]),ALLTRIM(_aVal[V,2])))

      Else
         
         _aFiliais:= FWLoadSM0()
         _lAchou := .F.
         For F := 1 to Len(_aFiliais)
            cFilAnt:=ALLTRIM(_aFiliais[F,2])
            If SX6->(DbSeek( cFilAnt + _aVal[V,1] ))
               _lAchou:=.T.
               Exit
            EndIf
         Next F

         If _lAchou .and. FWSX6Util():ReplicateParam( _aVal[V,1], {_cFilAtual} , .F. , .F. )
            cFilAnt:=_cFilAtual

            PutMv(_aVal[V,1],If(SX6->X6_TIPO="N",VAL(_aVal[V,2]),ALLTRIM(_aVal[V,2])))

            Aadd(_alog,{"Criado na filial",SX6->X6_FIL,_aVal[V,1],SX6->X6_TIPO,ALLTRIM(SX6->X6_CONTEUD)," ",LEFT(_aVal[V,4,1],Len(_aVal[V,4,1])-1) })
            //Aadd(_alog,{_aVal[V,1],_aVal[V,4,1]+": parametro FOI CRIADO para filial atual, conteudo digitado: " + ALLTRIM(SX6->X6_CONTEUD) + " na filial: ["+cFilAnt+"]"})

         ElseIf _lAmbTeste // Se não produção, cria o parâmetro
            _cDescri := SUBSTR((_aVal[V,4,2]),15)
            SX6->(RECLOCK("SX6",.T.))
            SX6->X6_FIL    :=_cFilAtual
            SX6->X6_VAR    :=ALLTRIM(_aVal[V,1])
            SX6->X6_TIPO   :=_aVal[V,5]
            SX6->X6_DESCRIC:=SUBSTR(_cDescri,0001,50)
            SX6->X6_DESC1  :=ALLTRIM(SUBSTR(_cDescri,051,100))
            SX6->X6_DESC2  :=ALLTRIM(SUBSTR(_cDescri,101))
            SX6->X6_CONTEUD:=ALLTRIM(_aVal[V,2])
            SX6->(MsUnlock())
            
            Aadd(_alog,{"Criado (teste)",SX6->X6_FIL,_aVal[V,1],SX6->X6_TIPO,ALLTRIM(SX6->X6_CONTEUD)," ",LEFT(_aVal[V,4,1],Len(_aVal[V,4,1])-1) })
            //Aadd(_alog,{_aVal[V,1],_aVal[V,4,1]+": parametro FOI CRIADO para filial atual, conteudo digitado: " + ALLTRIM(SX6->X6_CONTEUD) + " na filial: ["+_cFilAtual+"]"})

         Else
            
            Aadd(_alog,{"Não Criado, solicite p/ TI a criação",_cFilAtual,_aVal[V,1],_aVal[V,5],ALLTRIM(_aVal[V,2])," ",LEFT(_aVal[V,4,1],Len(_aVal[V,4,1])-1) })
            //Aadd(_alog,{_aVal[V,1],_aVal[V,4,1]+": parametro NÃO foi CRIADO para filial atual, solite ao TI a criação do mesmo, na filial: ["+_cFilAtual+"]"})

         EndIf
         
         cFilAnt := _cFilAtual
         
      EndIf
   EndIf

Next

If Len(_alog) == 0

   U_ITMSG("Nenhuma Alteração Realizada",'Atenção!',,3)

Else
   
   aCab:= {"Status","Filial","Parâmetro","Tipo","conteudo digitado","Conteudo Anterior","Descrição"}
   U_ITListBox( 'Ajustes Foram feitos nos parâmetros' , aCab , _alog , .T. , 1 , 'Os seguintes ajustes Foram feitos, veja status: ' )

EndIf

//Registra log de acesso a rotina
U_ITLOGACS('MEST017')

_oDlg:End()

Return .T.


/*
===============================================================================================================================
Programa----------: MEST017T
Autor-------------: André Lisboa
Data da Criacao---: 09/01/2017
Descrição---------: Funcao responsavel por manter o Layout indepEndente da resolucao horizontal do Monitor do Usuario.
Parametros--------: _nTam as Numeric
Retorno-----------: _nTam as Numeric
===============================================================================================================================
*/
Static Function MEST017T(_nTam as Numeric) as Numeric

Local _nHres	:=	oMainWnd:nClientWidth	// Resolucao horizontal do monitor

If _nHres == 640	// Resolucao 640x480 (soh o Ocean e o Classic aceitam 640)
   _nTam *= 0.8
ElseIf (_nHres == 798).Or.(_nHres == 800)	// Resolucao 800x600
   _nTam *= 1
Else	// Resolucao 1024x768 e acima faz proporcao
   _nTam = (_nTam * 1)
EndIf

Return Int(_nTam)



