/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
André Lisboa  |12/03/2024| Chamado 46558. Alteração na exibição campos motivo transf/descr transf/ incluido campo setor
Julio Paz     |20/05/2024| Chamado 46558. Desenvolvimento de melhorias nas rotinas de transferência de Produtos.
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"
#DEFINE USADO CHR(0)+CHR(0)+CHR(1)

/*
===============================================================================================================================
Programa----------: MA261CPO
Autor-------------: Talita Teixeira
Data da Criacao---: 09/05/2013 
Descrição---------: Ponto de entrada responsavel pela inclusão de campos na tela de inclusão da transf mod 2.Chamado 3254
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MA261CPO()

Local aTam := {} 
Local _cFilVld34 := SuperGetMV('IT_FILVLD3',.F.,'')

aTam := TamSX3('D3_I_OBS')
aAdd(aHeader, {'Observação'  ,'D3_I_OBS'   , PesqPict('SD3', 'D3_I_OBS'   , aTam[1]) , aTam[1], aTam[2], '', USADO, 'C', 'SD3', ''})

If ! xFilial("SD3") $ _cFilVld34 // Este campo não deve estar disponível para filiais de validação do armazém 34 (Descarte).
   aAdd(aHeader, {'Tipo TRS'   , 'D3_I_TPTRS' , PesqPict('SD3', 'D3_I_TPTRS' , 1) , 1, 0, '', USADO, 'C', 'SD3', ''})        
   aAdd(aHeader, {'Descric.Tipo TRS','D3_I_DSCTM' , PesqPict('SD3', 'D3_I_DSCTM' , 1) , 1, 0, '', USADO, 'C', '', ''})  
EndIf 

If xFilial("SD3") $ _cFilVld34 // Este campo não deve estar disponível para filiais de validação do armazém 34 (Descarte).
   aAdd(aHeader, {'Mot.Tran.Ref','D3_I_MOTTR' , PesqPict('SD3', 'D3_I_MOTTR' , 1) , 8, 0, '', USADO, 'C', 'SD3', ''})        
   aAdd(aHeader, {'Des.Mot.Tr.R','D3_I_DSCMT' , PesqPict('SD3', 'D3_I_DSCMT' , 1) , 40, 0, '', USADO, 'C', ''   , ''})  

   aAdd(aHeader, {'Origem Trf.' ,'D3_I_SETOR' , PesqPict('SD3', 'D3_I_SETOR' , 40) , 40, 0, '', USADO, 'C', '', ''}) // aAdd(aHeader, {'Setor Trf.'  ,'D3_I_SETOR' , PesqPict('SD3', 'D3_I_SETOR' , 6) , 6, 0, '', USADO, 'C', '', ''})       
   aAdd(aHeader, {'Destino'     ,'D3_I_DESTI' , PesqPict('SD3', 'D3_I_DESTI' , 40) , 40, 0, '', USADO, 'C', '', ''}) // aAdd(aHeader, {'Motiv.Transf','D3_I_MOTIV' , PesqPict('SD3', 'D3_I_MOTIV' , 6) , 6, 0, '', USADO, 'C', '', ''})          
EndIf 

Return 

/*
===============================================================================================================================
Programa----------: IT_TPTRS 
Autor-------------: Josué Danich Prestes
Data da Criacao---: 21/06/2017
Descrição---------: Controla when do campo D3_I_TPTRS
Parametros--------: Nenhum
Retorno-----------: .T. se campo é editável ou .F. se campo não é editável
===============================================================================================================================
*/
User Function IT_TPTRS

Local _lRet := .F.
Local _nLocal := 0
Local _oModel, _oModelGrid

If funname() == "MATA261"
	_nLocal := aScan(aHeader,{|x| AllTrim(x[1]) == "Armazem Destino"	})
	If acols[n][_nLocal] == '34'    
		_lRet := .T.
	EndIf
EndIf

If funname() == "MATA260"
	If M->D3_LOCAL == '34'
		_lRet := .T.
	EndIf
EndIf

If funname() == "MATA311"
   _oModel := FwModelActivete()
   _oModelGrid := _oModel:GetModel('NNTDETAIL')

   _cArmazemD  := _oModelGrid:GetValue("NNT_LOCLD") 

   If _cArmazemD == '34'
      _lRet := .T.
   EndIf 
EndIf 

Return _lRet
