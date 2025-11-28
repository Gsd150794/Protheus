/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |28/03/2025| Chamado 49970. Ajuste da leitura do Departamento do usuário para aprovação
Alex Wallauer |07/04/2025| Chamado 50402. Correcao das validações das datas da tabela de preço de AIA-> para M->.
Alex Wallauer |10/07/2025| Chamado 50990. Correção para não alterar as vairaevis de capa quando o lRetorno = .F. .
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: CM010TOK
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 28/06/2024
Descrição---------: PE de validação DO OK Final do Cadastro de tabela de preço de Fornecedores dentro da
                    função Com010Tok()/COMA010.PRX. Andre. Chamado: 47732
Parametros--------: ParamIXB[1]
Retorno-----------: lRetorno : .T. ou .F.
===============================================================================================================================
*/
User Function CM010TOK

Local nX
Local nPosProd:=aScan(aHeader,{|x| AllTrim(x[2])=="AIB_CODPRO"})
Local nPosMoed:=aScan(aHeader,{|x| AllTrim(x[2])=="AIB_MOEDA"})
Local lRetorno:=ParamIXB[1]
Local _aProd  :={}

If !lRetorno
   Return lRetorno
EndIf

AIB->(DBSetOrder(1))//AIB_FILIAL+AIB_CODFOR+AIB_LOJFOR+AIB_CODTAB+AIB_ITEM
AIA->(DBSetOrder(1))//AIA_FILIAL+AIA_CODFOR+AIA_LOJFOR+AIB_CODTAB

_cDep:="XXXXXXX"
PswOrder(1) // Busca por ID
If PSWSEEK(__cUserId, .T. )
   _aDados:=PSWRET(1)// Retorna vetor com informações do usuário
   _cDep  :=AllTrim(_aDados[1][12])// Departamento do usuário
EndIf

If Upper(_cDep) <> "DIRECAO"//para aprovação
   If M->AIA_I_SITW = "A" .And. (DToS(M->AIA_DATATE) >= DToS(DATE()) .Or. Empty(DToS(M->AIA_DATATE)))
      U_ITMsg("Tabela Aprovada não pode ser mais alterada.","Atenção",,1)
      lRetorno := .F.
   EndIf
EndIf

If lRetorno .And. Empty( M->AIA_I_DTDE ) .Or. Empty( M->AIA_I_DATE ) .Or. ( M->AIA_I_DTDE > M->AIA_I_DATE )
   U_ITMsg("Datas de aprovacao invalidas","Atenção",'Preencha as 2 datas com "Dt.Apr.Final" maior que a "Dt.Apr.Inici" e maior ou igual a hoje.',1)
   lRetorno := .F.
EndIf

nMoeda:=0
For nX := 1 To Len(aCols)
   If !aCols[nX][Len(aCols[nX])]
      If nMoeda = 0
         nMoeda:=aCols[nX][nPosMoed]
      ElseIf nMoeda <> aCols[nX][nPosMoed]
         U_ITMsg("Tabela com produtos com moedas distintas","Atenção","A Tabela de preços não pode ter produtos com moedas distintas.",1)////"PRODUTO: "+aCols[nX][nPosProd]+" com moeda distinta da moeda dos outros produtos, linha: "+StrZero(nX,3)
         lRetorno := .F.
         Exit
      EndIf
      If aScan(_aProd,aCols[nX][nPosProd]) > 0 //( nPosProd == 0 .Or. aCols[nX][nPosProd] == aCols[N][nPosProd])
         U_ITMsg("PRODUTO: "+aCols[nX][nPosProd]+" repetido, linha: "+StrZero(nX,3),"Atenção","Delete o produto ate ficar uma linha somente dele.",1)
         lRetorno := .F.
      Else
         aAdd(_aProd,aCols[nX][nPosProd])
      EndIf
   EndIf
Next

//===============================================================================================================
// AO INSERIR NOVAS VALIDAÇÕES SOMENTE ACIMA DAQUI , NADA ABAIXO DO If ABAIXO , SOMENTE ALTERAÇÕES QUE GRAVAM
//===============================================================================================================

If lRetorno
   If Upper(_cDep) <> "DIRECAO"//para aprovação
      M->AIA_DATDE :=DATE()-2
      M->AIA_DATATE:=DATE()-1
   Else//DIRETORIA TEM APROVACAO AUTOMATICO
      M->AIA_DATDE :=M->AIA_I_DTDE
      M->AIA_DATATE:=M->AIA_I_DATE
      M->AIA_I_SITW:="A"
      M->AIA_I_APRO:="Aprovado Automatico por Sr "+Capital(RTrim(UsrFullName(__cUserId)))+" no dia "+DToC(DATE())+' as '+Time()
   EndIf
EndIf

If lRetorno .And. Inclui
   AIA->(DBSetOrder(1))//AIA->(AIA_FILIAL+AIA_CODFOR+AIA_LOJFOR)
   While AIA->(DBSeek(xFilial("AIA")+M->AIA_CODFOR+M->AIA_LOJFOR+M->AIA_CODTAB))//QUANDO INCLUSAO
      U_M026Num()//GRAVA A VARIAVEL  " M->AIA_CODTAB "
   EndDo
EndIf

If lRetorno
   SBZ->(DBSetOrder(1))//BZ_FILIAL+BZ_COD
   For nX := 1 To Len(aCols)
      If !aCols[nX][Len(aCols[nX])]//DELETADOS
         If SBZ->(DBSeek(xFilial("SBZ")+aCols[nX][nPosProd])) .And. SBZ->BZ_I_VLDTP <> "S"
            SBZ->(RecLock("SBZ",.F.))
            SBZ->BZ_I_VLDTP:= "S"
            SBZ->(MSUnLock())
         EndIf
      EndIf
   Next
EndIf

Return lRetorno
