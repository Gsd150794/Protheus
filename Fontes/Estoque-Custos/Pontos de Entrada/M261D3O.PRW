/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
André Lisboa  |12/03/2024| Chamado 46558. Alteração na exibição campos motivo transf/descr transf/ incluido campo setor.
Julio Paz     |23/05/2024| Chamado 46558. Desenvolvimento de melhorias rotina Transf.Produto.Gravação campo D3_I_DESTI
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: M261D3O
Autor-------------: Talita Teixeira
Data da Criacao---: 06/06/2013 
Descrição---------: Ponto de entrada responsavel pela gravação na tela de inclusão da transf mod 2 Chamado 3254
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function M261D3O
 
Local nPosObs     := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_OBS"  })  
Local _ntptrs     //:= aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_TPTRS"})
Local _nDsctptrs  //  := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_DSCTM"})
Local _nSetor     //  := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_SETOR"})
Local _nPosdest   //  := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_DESTI"})
Local _nMotTrRef  //  := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_MOTTR"})
Local _nDscMTrRf  //  := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_DSCMT"})
Local _cFilVld34  := SuperGetMV('IT_FILVLD3',.F.,'')

Public n := ParamIXB 

If ! xFilial("SD3") $ _cFilVld34 
   _ntptrs    := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_TPTRS"}) // Este campo não pode ser considerado quando as validações do Armazém 34(descarte) estiver habilitada. 
   _nDsctptrs := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_DSCTM"})
EndIf 

If xFilial("SD3") $ _cFilVld34 
   _nSetor       := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_SETOR"})
   _nPosdest     := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_DESTI"})
   _nMotTrRef    := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_MOTTR"})
   _nDscMTrRf    := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_DSCMT"})
EndIf 

//No. da linha do aCols que esta sendo processado
//-- 'Atualização de campos desejados pelo usuario - Tabela SD3' 

RecLock("SD3", .F.)

SD3->D3_I_OBS  := aCols[n][nPosObs]  

If ! xFilial("SD3") $ _cFilVld34 
   SD3->D3_I_TPTRS:= aCols[n][_ntptrs]  
   SD3->D3_I_DSCTM:= aCols[n][_nDsctptrs] 
EndIf 

If xFilial("SD3") $ _cFilVld34 
   SD3->D3_I_SETOR:= aCols[n][_nSetor]  
   SD3->D3_I_MOTTR := aCols[n][_nMotTrRef] 
   SD3->D3_I_DSCMT := aCols[n][_nDscMTrRf]  
   If _nPosdest > 0
      SD3->D3_I_DESTI := aCols[n][_nPosdest] 
   EndIf 
EndIf 

SD3->(MSUnLock()) 

Return 
