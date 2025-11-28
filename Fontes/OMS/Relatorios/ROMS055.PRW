/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
     Autor   |   Data   |                                             Motivo                                           
===============================================================================================================================
Josué Danich | 16/01/19 | Chamado 27724. Inclusão de opção de visualizar nota de débito.
Josué Danich | 25/02/19 | Chamado 28191. Ajustes diversos de geração de nota de débito.
Lucas Borges | 17/10/19 | Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Jerry        | 09/12/19 | Chamado 31404. Alterar busca do NDT para qdo Ped.Troca Nota informar Filial de Carregamento.
Julio Paz    | 15/09/20 | Chamado 34128. Correções na busca títulos NDT quando há mais de uma ocorrencia e PV Troca nota.
Alex Wallauer| 07/08/24 | Chamado 48035. Andre. Gravação e tratamento do campo novo ZF5_CHVNDT da chave do Titulo NDT.
==============================================================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==============================================================================================================================================================
Bremmer  - Alex Wallauer - 11/10/24 - 11/10/24 -  47942  - Correção da Gravação e tratamento do campo novo ZF5_CHVNDT da chave do Titulo NDT.
Jerry    - Alex Wallauer - 29/01/25 - 05/02/25 -  49663  - Novo tratamento do campo ZF5_CHVNDT da chave do Titulo para gravar a parcela e colocar no e-mail.
Alex     - Igor Melgaço  - 02/05/25 - 06/05/25 -  50525  - Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
==============================================================================================================================================================
*/

// Definicoes de Includes e Defines da Rotina.
#Include "TOTVS.ch"
#Include "RPTDEF.CH"
#Include "TBICONN.CH"
#Include "FONT.CH"
#Include 'totvs.ch'

/*
===============================================================================================================================
Programa----------: ROMS055I
Autor-------------: Josué Danich Prestes
Data da Criacao---: 27/12/2018
Descrição---------: Rotina responsável por emitir nota de débito de transporte - Chamado 27268
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS055I()
 Local _aArea  := FwGetArea() As Array
 Local _aAreaF5:= ZF5->(FwGetArea()) As Array
 Local _aAreaM0:= SM0->(FwGetArea()) As Array
 Local _cfilial:= ZF5->ZF5_FILIAL As Character
 Local _cdococ := ZF5->ZF5_DOCOC  As Character
 Local _limp   := .F. As Logical
 Local _cFilSeek As Character
 
 ZF5->(DBSetOrder(1))
 If ZF5->(DBSeek(_cfilial+_cdococ))

    While ZF5->ZF5_FILIAL == _cfilial .And. ZF5->ZF5_DOCOC == _cdococ  .And. ZF5->(!Eof()())

       If !(ZF5->ZF5_NDEBIT = 'S')
          ZF5->(DBSkip())  
          Loop
       EndIf
        _cFilSeek := _cfilial

        SC5->(DBSetOrder(1))
        If SC5->(DBSeek(_cfilial+ZF5->ZF5_PEDIDO))
            If  ( SC5->C5_I_TRCNF = "S" .And. _cFilial <> SC5->C5_I_FLFNC) // Qdo Troca Nota o Título NDT é gerado na Filial de Carregamento.
                _cFilSeek := SC5->C5_I_FLFNC
            EndIf
        EndIf	

        _ccodigo:= AllTrim(Str(Val(ZF5->ZF5_CODIGO)))
        _cFornece:=""
        _cLoja:=""
        If ZF5->ZF5_TIPOC == "T"
           _cFornece := AllTrim(ZF5->ZF5_TRANSP)
           _cLoja    := ZF5->ZF5_LJTRAN
        ElseIf ZF5->ZF5_TIPOC == "3"
           _cFornece := ZF5->ZF5_FORTER
           _cLoja    := ZF5->ZF5_LOJTER
        EndIf

        If !Empty(ZF5->ZF5_CHVNDT)
           If Len(AllTrim(ZF5->ZF5_CHVNDT)) = Len(SE2->E2_FILIAL+SE2->E2_PREFIXO+SE2->E2_NUM)//CHAVE SEM PARCELA
              _cSeekSE2:=ZF5->ZF5_CHVNDT + "01" + "NDF"//A chave e o cfilant já estam com a filial certa
           Else//CHAVE COM PARCELA - NOVO
              _cSeekSE2:=ZF5->ZF5_CHVNDT + "NDF"+_cFornece+_cLoja//A chave e o cfilant já estam com a filai certa
           EndIf
        Else
           _cSeekSE2:=_cFilSeek+"NDT"+SubStr(ZF5->ZF5_DOCOC,2,8) + _ccodigo + "01" + "NDF"
        EndIf

        SE2->(DBSetOrder(1)) // E2_FILIAL+E2_PREFIXO+E2_NUM   +E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
            
           If SE2->(DBSeek(_cSeekSE2))   

               _limp := .T.
               FWMsgRun(,{|| ROMS055E()},,"Aguarde, imprimindo nota de débito...")
               
           EndIf
           
           ZF5->(DBSkip())
           
       EndDo
       
       If !_limp
       
           U_ITMsg("Não foram localizadas notas de débito para essa ocorrência","Atenção",,1)
           
       EndIf
       
 Else
     U_ITMsg("Ocorrência não localizada","Atenção",,1)
 EndIf
 
 FwRestArea(_aArea)
 FwRestArea(_aAreaF5)
 FwRestArea(_aAreaM0)
Return


/*
===============================================================================================================================
Programa----------: ROMS055
Autor-------------: Josué Danich Prestes
Data da Criacao---: 27/12/2018
Descrição---------: Imprime nota de débito
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS055()
 Local _aArea:= FWGetArea() As Array

 FWMsgRun(,{|| ROMS055E()},,"Aguarde, gerando nota de débito...")

 FWRestArea(_aArea)
Return


/*
===============================================================================================================================
Programa----------: ROMS055E
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/02/2018
Descrição---------: Rotina responsável por emitir nota de débito em PDF por e-mail
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS055E()
 Local _aArea	:= FWGetArea() As Array
 Local _cAnexo	:= "" As Character
 Local _cEmail	:= "" As Character
 Local _cCc		:= "" As Character
 Local _cAssunto:= "" As Character
 Local _cMens	:= "" As Character
 Local cPathSrvJ:= GETMV("MV_RELT") As Character
 Local nLinIni	:= 10 As Numeric
 Local nCont	:= 0  As Numeric
 Local cNReduz	:= "" As Character
 Local cCidUni	:= "" As Character
 Local cNomUsr	:= "" As Character
 Local lPagina	:= .T. As Logical
 Local _cFilial := SE2->E2_FILIAL As Character
 Local cMailCom := "" As Character
 Local _aAreaM0:= SM0->(FwGetArea()) As Array
 
 Private oPrint  := Nil As Object
 Private nLinAux := 0   As Numeric
 Private nColIni := 10  As Numeric
 Private ltemmil := .F. As Logical
 Private oFont10 := TFont():New("Arial",,10,,.T.,,,,,.F.,.F.) As Object
 Private oFont14 := TFont():New("Arial",,14,,.F.,,,,,.F.,.F.) As Object
 Private oFont04 := TFont():New("Arial",,04,,.F.,,,,,.F.,.F.) As Object
 Private oFont08 := TFont():New("Arial",,08,,.F.,,,,,.F.,.F.) As Object
 Private oFont06 := TFont():New("Arial",,06,,.F.,,,,,.F.,.F.) As Object
 Private oFont16b:= TFont():New("Arial",,16,,.T.,,,,,.F.,.F.) As Object
 
 cFileName := "notadebitotransp_" + SE2->E2_FILIAL+"_"+Lower(SE2->E2_NUM+"_"+SE2->E2_PARCELA) + ".pdf"

 // Cria Arquivo do Relatorio
 oPrint := FWMSPrinter():New( cFileName , IMP_PDF , .F. , cPathSrvJ , .T. ,,,, .T. )
 
 // Configura modo Paisagem de Impressao
 oPrint:SetLandscape()
 
 //=============================
 // Define impressao em papel A4
 //=============================
 oPrint:SetPaperSize(9)
 oPrint:SetMargin(0,0,0,0)	// nEsquerda, nSuperior, nDireita, nInferior
     
 //=========================================================
 // Se enviar por e-mail nao abre o arquivo apos a impressao
 //=========================================================
 oPrint:SetViewPDF(.F.)
 oPrint:cPathPDF := cPathSrvJ	// Caso seja utilizada impressão em IMP_PDF

 oPrint:StartPage()
 
 //==================================
 // Chama função para desenhar o grid
 //==================================
 ROMS055G()

 nLinIni	:= 005
 nColIni	:= 000
 nCont++
 
 If nLinAux > (nLinIni+590)
     lPagina := .T.
     oPrint:EndPage()
     oPrint:StartPage()
     ROMS055G() 
     nLinIni	:= 005
     nColIni	:= 000
     nCont++
 EndIf

 oPrint:Say( (nLinIni+035) , (nColIni+375) , "NOTA DE DÉBITO DE TRANSPORTE" , oFont14 )
 oPrint:Say( (nLinIni+050) , (nColIni+700) , "Nº " + SE2->E2_FILIAL + "/" + SE2->E2_NUM+ "-" + SE2->E2_PARCELA , oFont14 )
 oPrint:Say( (nLinIni+070) , (nColIni+700) , "R$ " + transform(SE2->E2_VALOR,"@E 999,999.99") , oFont14 )
 oPrint:Say( (nLinIni+090) , (nColIni+700) , "Emissão: " + DToC(SE2->E2_EMISSAO) , oFont14 )
 oPrint:Say( (nLinIni+110) , (nColIni+700) , "Vencimento: " + DToC(SE2->E2_VENCTO) , oFont14 )
 SM0->(DBSetOrder(1))
 SM0->(DBSeek(cEmpAnt + _cFilial))
 oPrint:Say( (nLinIni+080) , (nColIni+020) , AllTrim(SM0->M0_NOMECOM) , oFont08 )
 oPrint:Say( (nLinIni+090) , (nColIni+020) , AllTrim(SM0->M0_ENDCOB) , oFont08 )
 oPrint:Say( (nLinIni+100) , (nColIni+020) , "CEP: " + SubStr(AllTrim(SM0->M0_CEPCOB),1,2) + "." + SubStr(AllTrim(SM0->M0_CEPCOB),3,3) + "-" + SubStr(AllTrim(SM0->M0_CEPCOB),6,3) + " - " + SubStr(AllTrim(SM0->M0_CIDCOB),1,50) + " - " + AllTrim(SM0->M0_ESTCOB) , oFont08 )
 oPrint:Say( (nLinIni+110) , (nColIni+020) , 'TEL:(' + SubStr(SM0->M0_TEL,4,2) + ')' + SubStr(SM0->M0_TEL,7,4) + '-' +SubStr(SM0->M0_TEL,11,4) + " - " + 'FAX:(' + SubStr(SM0->M0_FAX,4,2) + ')' + SubStr(SM0->M0_FAX,7,4) + '-' +SubStr(SM0->M0_FAX,11,4), oFont08 )
 oPrint:Say( (nLinIni+120) , (nColIni+020) , "CNPJ/CPF:" + ROMS055CN(SM0->M0_CGC) , oFont08 )
 oPrint:Say( (nLinIni+130) , (nColIni+020) , "I.E:" + AllTrim(SM0->M0_INSC) , oFont08 )
 DBSelectArea("SA2")
 DBSetOrder(1)
 DBSeek(xFilial("SA2") + SE2->E2_FORNECE+SE2->E2_LOJA)
 
 oPrint:Say( (nLinIni+080) , (nColIni+260) , AllTrim(SA2->A2_NOME) + " - " + SA2->A2_COD + "/" + SA2->A2_LOJA , oFont08 )
 oPrint:Say( (nLinIni+090) , (nColIni+260) ,  AllTrim(SA2->A2_END) , oFont08 )
 oPrint:Say( (nLinIni+100) , (nColIni+260) , "CEP: " + SubStr(AllTrim(SA2->A2_CEP),1,2) + "." + SubStr(AllTrim(SA2->A2_CEP),3,3) + "-" + SubStr(AllTrim(SA2->A2_CEP),6,3) + " - " + AllTrim(SA2->A2_MUN) + " - " + SA2->A2_EST , oFont08 )
 oPrint:Say( (nLinIni+110) , (nColIni+260) , "TEL:(" + AllTrim(SA2->A2_DDD) + ") " + SubStr(AllTrim(SA2->A2_TEL),1,4) + "-" + SubStr(AllTrim(SA2->A2_TEL),5,4) + " - " + "FAX:(" + AllTrim(SA2->A2_DDD) + ") " + SubStr(AllTrim(SA2->A2_FAX),1,4) + "-" + SubStr(AllTrim(SA2->A2_FAX),5,4) , oFont08 )
 oPrint:Say( (nLinIni+120) , (nColIni+260) , "CNPJ/CPF: " + ROMS055CN(SA2->A2_CGC) + " - I.E:" + SA2->A2_INSCR , oFont08 )
 
 
 nLinAux := nLinIni + 220
 oPrint:Say( (nLinAux) , (nColIni+40) ,  "Nota de débito referente a ocorrência de frete no. " + AllTrim(ZF5->ZF5_CODIGO) + " da nota fiscal " + AllTrim(ZF5->ZF5_DOCOC) + " da carga " + AllTrim(ZF5->ZF5_CARGA) + ".", oFont14 )
 
 oPrint:Say( (nLinAux+30) , (nColIni+40) ,  "Destino: " + AllTrim(ZF5->ZF5_NCLIEN) + ", " + AllTrim(ZF5->ZF5_CIDADE) + " - " + ZF5->ZF5_UF + ".", oFont14 )
 
 oPrint:Say( (nLinAux+60) , (nColIni+40) ,  "Data de carregamento: " + DToC(ZF5->ZF5_DTCAR) + ",  data da ocorrência: " + DToC(ZF5->ZF5_DTINI) + ".", oFont14 )
 
 oPrint:Say( (nLinAux+90) , (nColIni+40) ,  "Placa do Veículo: " + AllTrim(ZF5->ZF5_PLACA)  + ".", oFont14 )
 
 oPrint:Say( (nLinAux+120) , (nColIni+40) ,  " Motorista: " + AllTrim(ZF5->ZF5_DMOTOR) + ".", oFont14 )
 
 oPrint:Say( (nLinAux+150) , (nColIni+40) ,  "Motivo da ocorrência: " + AllTrim(ZF5->ZF5_MOTIVO)  + ".", oFont14 )
 
 oPrint:Say( (nLinAux+180) , (nColIni+40) ,  "Motivo do custo: " + AllTrim(ZF5->ZF5_MOTCUS)  + ".", oFont14 )

 _cEmail := SA2->A2_EMAIL

 oPrint:EndPage()
 oPrint:lViewPDF := .F.
 oPrint:Preview()
 FreeObj(oPrint)
 
 If File(cPathSrvJ + cFileName)
     _cAnexo := cPathSrvJ + cFileName
 EndIf
 
 cNreduz := AllTrim(Posicione("SA2",1,xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA,"A2_NREDUZ"))
 
 _cAssunto := "Nota de débito de transporte - " + SE2->E2_FILIAL + "/" + SE2->E2_NUM+ "-" + SE2->E2_PARCELA + " - ITALAC - " + SubStr(AllTrim(SM0->M0_CIDCOB),1,50) + " - " + AllTrim(SM0->M0_ESTCOB) + ":" + cNReduz + Space(30)

 //=================================
 // Chama a função da tela de E-mail
 //=================================
 _cCc := Lower(AllTrim(UsrRetMail(__cUserId)))
 ROMS055M(_cAnexo,@_cEmail,@_cCc,@_cAssunto,@_cMens,cMailCom,cNReduz,_cFilial,SE2->E2_NUM,cCidUni,cNomUsr)
 
 //========================================================
 // Chama a função para exclusão do arquivo PDF do servidor
 //========================================================
 ROMS055D(cPathSrvJ + cFileName)
 
 FWRestArea(_aArea)
 FwRestArea(_aAreaM0)

Return

/*
===============================================================================================================================
Programa----------: ROMS055G
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/02/2018
Descrição---------: Rotina responsável por criar o layout de impressão
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS055G()
 Local nLinIni := 0 As Numeric
 Local nColIni := 0 As Numeric
 Local nLinMax := 0600 As Numeric
 Local nColMax := 0835 As Numeric
 Local cPathImg:= GetSrvProfString("Startpath","") As Character
 Local cFileImg:= "" As Character
 
 nLinIni:= 005
 nColIni:= 000
 
 cFileImg := cPathImg + "LGRL01.BMP"
 
 //==============
 // Box Principal
 //==============
 oPrint:Box( nLinIni + 008, nColIni + 010, nLinMax, nColMax, "-4")
 
 //=========
 // Logotipo
 //=========
 oPrint:SayBitmap( nLinIni + 010 , nColIni + 018 , cFileImg , 170 , 058 )
 
 //=================
 // Linha Horizontal
 //=================
 oPrint:Line( nLinIni + 145 , nColIni + 010 , nLinIni + 145 , nColMax	)
 
 //===============
 // Linha Vertical
 //===============
 oPrint:Line( nLinIni + 008 , nColIni + 200 , nLinIni + 145 , nColIni + 200	)
 
 //===============
 // Linha Vertical
 //===============
 oPrint:Line( nLinIni + 008 , nColIni + 650 , nLinIni + 145 , nColIni + 650	)
 
 //=================
 // Linha Horizontal
 //=================
 oPrint:Line( nLinIni + 050 , nColIni + 200 , nLinIni + 050 , nColIni + 650	)
 
 //=================
 // Linha Horizontal
 //=================
 oPrint:Line( nLinIni + 165 , nColIni + 010 , nLinIni + 165 , nColMax	)

Return


/*
===============================================================================================================================
Programa----------: ROMS055M
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/02/2018
Descrição---------: Função responsável por exibir a janela para a digitação dos endereços de email, assunto, mensagem
Parametros--------: _cAnexo		- Endereço do arquivo da nota de débito em PDF
------------------: _cEmail		- Endereço de E-mail para qual será enviado a nota de débito
------------------: _cCc		- Endereço de E-mail que está no campo Com Cópia
------------------: _cAssunto	- Assunto do E-mail
------------------: _cMens		- Mensagem de texto para o corpo do E-mail
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS055M(_cAnexo As Character, _cEmail As Character, _cCc As Character, _cAssunto As Character, _cMens As Character, cMailCom As Character, cNReduz As Character, _cFilial As Character, _cNumPC As Character, cCidUni As Character, cNomUsr As Character)
 Local oAnexo    As Object
 Local oAssunto  As Object
 Local oButCan   As Object
 Local oButEnv   As Object
 Local oCc       As Object
 Local oGetAnx   As Object
 Local oGetAssun As Object
 Local oGetCc    As Object
 Local oGetPara  As Object
 Local oMens     As Object
 Local oPara     As Object
 Local _csetor  := "" As Character
 Local _aConfig := U_ITCFGEML("") As Array
 Local _cEmlLog := "" As Character
 Local cHtml    := "" As Character
 Local nOpcA    := 2 As Numeric
 Local cGetAnx	:= _cAnexo As Character
 Local cPathSrvJ:= GETMV("MV_RELT") As Character
 Local cPatLocal:= GetTempPath() As Character
 Local cGetAnxl := StrTran(cGetAnx, cPathSrvJ, cPatLocal+"\") As Character
 Local cGetAssun:= _cAssunto As Character
 Local cGetCc   := _cCc + Space(180) As Character
 Local cGetMens := "" As Character
 Local cGetPara := _cEmail + Space(180) As Character
 Local _lBotao  := .T. As Logical
 
 Private oDlgMail As Object
 
 //Copia anexo para estação local
 If !CpyS2T(cGetAnx,cPatLocal)
    _lBotao:=.F.
 EndIf
 
 If (Len(PswRet()) # 0) // Quando nao For rotina automatica do configurador
     _csetor:= AllTrim(PswRet()[1][12])		// Pega departamento do usuario
 EndIf
 
 
 If Empty(AllTrim(_csetor))
      _csetor := "Logistica"
 EndIf
 
 cHtml := 'À '+ Posicione("SA2",1,xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA,"A2_NREDUZ") +','
 cHtml += '<br><br>'
 cHtml += '&nbsp;&nbsp;&nbsp;Segue anexo Nota de débito de transporte - ' + SE2->E2_FILIAL + "/"  + SE2->E2_NUM+ "-" + SE2->E2_PARCELA + ' de nossa Unidade Industrial '+ cCidUni +' conforme negociado em ocorrência de frete.<br>'
 cHtml += '&nbsp;&nbsp;&nbsp;Favor confirmar o recebimento, retornando com o seu CIENTE!'
 cHtml += '<br><br>'
 cHtml += '<font color="#FF0000"><b><u>Título: ' + SE2->E2_NUM+ "-" + SE2->E2_PARCELA + ' no valor de ' + transform(SE2->E2_VALOR,"@E 999,999.99") + ' com vencimento em ' + DToC(SE2->E2_VENCTO) +'. </u></b><br><br></font>'
 cHtml += '<br><br>'
 
 
 cHtml += '&nbsp;&nbsp;&nbsp;A disposição!'
 cHtml += '<br><br>'
 
 
 cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
 cHtml += '<tr>'
 cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">'
 cHtml +=         '<p class=MsoNormal align=center style="text-align:center">'
 cHtml +=             '<b><span style="font-size:18.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">'+ Capital( AllTrim( UsrFullName( __cUserId ) ) ) +'</span></b>'
 cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
 cHtml +=     '</td>'
 cHtml +=     '<td style="background:#A2CFF0;padding:.75pt .75pt .75pt .75pt">&nbsp;</td>'
 cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">
 cHtml +=         '<table class=MsoNormalTable border=0 cellpadding=0>'
 cHtml +=              '<tr>'
 cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">'
 cHtml +=                      '<p class=MsoNormal><b><span style="font-size:13.5pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#6FB4E3;mso-fareast-language:PT-BR">' + _cSetor + '</span></b>'
 cHtml +=                      '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></b>
 cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"><br></span>
 cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
 cHtml +=                  '</td>'
 cHtml +=              '</tr>'
 cHtml +=              '<tr>'
 cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">
 cHtml +=                      '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Tel: ' + Posicione("SY1",3,xFilial("SY1") + __cUserId,"Y1_TEL") + '</span>'
 cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
 cHtml +=                  '</td>'
 cHtml +=              '</tr>'
 cHtml +=         '</table>'
 cHtml +=     '</td>'
 cHtml += '</tr>'
 cHtml += '</table>'
 cHtml += '<table class=MsoNormalTable border=0 cellpadding=0 width=437 style="width:327.75pt">'
 cHtml +=     '<tr>'
 cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
 cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
 cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR">'
 cHtml +=                 '<img width=400 height=51 src="http://www.italac.com.br/assinatura-italac/images/marcas-goiasminas-industria-de-laticinios-ltda.jpg">'
 cHtml +=             '</span>
 cHtml +=             '</p>'
 cHtml +=         '</td>'
 cHtml +=     '</tr>'
 cHtml += '</table>'
 cHtml += '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';display:none;mso-fareast-language:PT-BR">&nbsp;</span></p>'
 cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
 cHtml +=     '<tr>'
 cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
 cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
 cHtml +=             '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Política de Privacidade </span></b>'
 cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
 cHtml +=             '<p class=MsoNormal style="mso-margin-top-alt:auto;mso-margin-bottom-alt:auto;text-align:justify">'
 cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">
 cHtml +=                 'Esta mensagem é destinada exclusivamente para fins profissionais, para a(s) pessoa(s) a quem For dirigida, podendo conter informação confidencial e legalmente privilegiada. '
 cHtml +=                 'Ao recebê-la, se você não For destinatário desta mensagem, fica automaticamente notificado de abster-se a divulgar, copiar, distribuir, examinar ou, de qualquer forma, utilizar '
 cHtml +=                 'sua informação, por configurar ato ilegal. Caso você tenha recebido esta mensagem indevidamente, solicitamos que nos retorne este e-mail, promovendo, concomitantemente sua '
 cHtml +=                 'eliminação de sua base de dados, registros ou qualquer outro sistema de controle. Fica desprovida de eficácia e validade a mensagem que contiver vínculos obrigacionais, expedida '
 cHtml +=                 'por quem não detenha poderes de representação, bem como não esteja legalmente habilitado para utilizar o referido endereço eletrônico, configurando falta grave conforme nossa '
 cHtml +=                 'política de privacidade corporativa. As informações nela contidas são de propriedade da Italac, podendo ser divulgadas apenas a quem de direito e devidamente reconhecido pela empresa.'
 cHtml +=             '</span>'
 cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>'
 cHtml +=         '</td>'
 cHtml +=     '</tr>
 cHtml += '</table>'

 DEFINE MSDIALOG oDlgMail TITLE "E-Mail" FROM 000, 000  TO 415, 584 COLORS 0, 16777215 PIXEL

    //======
    // Para:
    //======
    @ 005, 006 Say oPara PROMPT "Para:" SIZE 015, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
    @ 005, 030 MSGET oGetPara VAR cGetPara SIZE 256, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL

    //===========
    // Com cópia:
    //===========
    @ 021, 006 Say oCc PROMPT "Cc:" SIZE 015, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
    @ 021, 030 MSGET oGetCc VAR cGetCc SIZE 256, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL

    //=========
    // Assunto:
    //=========
    @ 037, 006 Say oAssunto PROMPT "Assunto:" SIZE 022, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
    @ 037, 030 MSGET oGetAssun VAR cGetAssun SIZE 256, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL

    //======
    // Anexo
    //======
    @ 053, 006 Say oAnexo PROMPT "Anexo:" SIZE 019, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
    @ 053, 030 MSGET oGetAnx VAR cGetAnx SIZE 256, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 READONLY PIXEL

    //==========
    // Mensagem:
    //==========
    @ 069, 006 Say oMens PROMPT "Mensagem:" SIZE 030, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
    _oFont		:= TFont():New( 'Courier new' ,, 12 , .F. )
    _oScrAux	:= TSimpleEditor():New( 080 , 006 , oDlgMail , 285 , 105 ,,,,, .T. )
    
    _oScrAux:Load( cHtml )
    If _lBotao
       @ 189, 154 BUTTON oButEnv PROMPT "&Visualizar"	SIZE 037, 012 OF oDlgMail ACTION ( ShellExecute("open", cGetAnxl, "", cPatLocal, 1) ) PIXEL
    EndIf
    @ 189, 201 BUTTON oButEnv PROMPT "&Enviar"		SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 1 , cHtml := _oScrAux:RetText() , oDlgMail:End() ) PIXEL
    @ 189, 245 BUTTON oButCan PROMPT "&Cancelar"	SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 2 , oDlgMail:End() ) PIXEL

 ACTIVATE MSDIALOG oDlgMail CENTERED
 
 If nOpcA == 1
    cGetMens := ROMS055TT(cGetMens)
    //====================================
    // Chama a função para envio do e-mail
    //====================================
    cGetPara  := Lower(AllTrim(cGetPara))
    cGetCc    := Lower(AllTrim(cGetCc))
    _cEmailUsr:= Lower(AllTrim(UsrRetMail(__cUserId)))
    U_ITENVMAIL( _cEmailUsr, cGetPara,cGetCc, cMailCom, AllTrim(cGetAssun), cHtml, cGetAnx, _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
 
     _cEmlLog := Upper(_cEmlLog)
     If !Empty( _cEmlLog ) .And. "SUCESSO" $ _cEmlLog
        U_ITMsg("E-mail enviado com SUCESSO para: "+cGetPara+", "+cGetCc,'Atenção!',,2) // OK
     Else
        U_ITMsg("E-mail NÃO enviado para: "+cGetPara+", "+cGetCc,'Atenção!',_cEmlLog,1)
     EndIf
 
 Else
     U_ITMsg( 'Envio de e-mail cancelado pelo usuário.' , 'Atenção!' , ,1 )
 EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS055D
Autor-------------: Josué Danich Prestes
Data da Criacao---: 11/02/2018
Descrição---------: Função responsável pela exclusão do arquivo pdf gerado no servidor
Parametros--------: cFile	- Caminho + nome do arquivo pdf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS055D(cFile As Character)
 Local nRet := 0 As Numeric
 
 If File(cFile)
    nRet := fErase(cFile)
    If nRet <> 0
        u_itconout("Erro ao excluir o arquivo: " + cFile + " - Erro: " + Str(FError()))
    EndIf
 EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS055CN
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 14/01/2018                                      
===============================================================================================================================
Descrição---------: Função criada para formatar CPF/CNPJ
===============================================================================================================================
Parametros--------: cCPFCNPJ	- Texto a ser quebrado
===============================================================================================================================
Retorno-----------: cCampFormat	- Retorna o campo formatado conforme CPF/CNPJ
===============================================================================================================================
*/
Static Function ROMS055CN(cCPFCNPJ As Character)
 Local cCampFormat := ""	As Character    //Armazena o CPF ou CNPJ formatado
    
 If Len(AllTrim(cCPFCNPJ)) == 11//CPF
     cCampFormat:=SubStr(cCPFCNPJ,1,3) + "." + SubStr(cCPFCNPJ,4,3) + "." + SubStr(cCPFCNPJ,7,3) + "-" + SubStr(cCPFCNPJ,10,2) 
 Else//CNPJ
     cCampFormat:=SubStr(cCPFCNPJ,1,2)+"."+SubStr(cCPFCNPJ,3,3)+"."+SubStr(cCPFCNPJ,6,3)+"/"+SubStr(cCPFCNPJ,9,4)+"-"+ SubStr(cCPFCNPJ,13,2)
 EndIf
    
Return cCampFormat

/*
===============================================================================================================================
Programa----------: ROMS055TT
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 12/02/2018
===============================================================================================================================
Descrição---------: Função criada para fazer a quebra de linha na mensagem digitada pelo usuário
===============================================================================================================================
Parametros--------: ExpC1	- Texto da mensagem
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS055TT(cGetMens As Character)
 Local aTexto := StrTokArr(cGetMens, CRLF) As Array
 Local cRet   := "" As Character
 Local nI     := 0 As Numeric
 
 For nI := 1 To Len(aTexto)
     cRet += aTexto[nI] + "<br>"
 Next nI

Return(cRet)
