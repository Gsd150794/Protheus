/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RCFG002
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/04/2019
Descrição---------: Relatorio de último acesso de usuários - Chamado 28767
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCFG002()

Local oproc := nil

Private _aLista:= {}
Private _aTit  := {}

Begin Sequence

lSair:=.F.
FWMsgRun(,{|oproc| lSair:=RCFG002Ger(oproc) },"Aguarde...","Carregando histórico..." )

If lSair
	If Len(_ALISTA) == 0
		U_ITMsg("Não foram localizados registros","Atenção",,1)
	EndIf
    BREAK
EndIf

RCFG002Tela()

End Sequence

Return

/*
===============================================================================================================================
Programa----------: RCFG002Tela
Autor-------------: Josué Danich
Data da Criacao---: 04/04/2019
Descrição---------: Relatorio de último acesso de usuários
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCFG002Tela()

Begin Sequence
   
   _atit :=  	{   "Nome",;               
									"Login",;                   
									"Email" ,;               
									"Departamento" ,;               
									"Cargo"  ,;                    
									"Data Ult Acesso"  ,;               
									"Hora Ult Acesso" ,;               
									"IP do Ult Acesso" ,;  
									"Estação do Ult Acesso" ,;      
									"Usuário Windows" }               

   lRet := U_ITListBox('Relatorio de último acesso de usuários',_aTit,_aLista, .T. , 1 )

End Sequence

Return !lRet

/*
===============================================================================================================================
Programa----------: RCFG002Ger
Autor-------------: Josué Danich
Data da Criacao---: 04/04/2019
Descrição---------: Executa relatório
Parametros--------: oproc - Objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCFG002Ger(oproc)

Local _ausers := FWSFALLUSERS()
Local _nni := 1

For _nni := 1 to Len(_ausers)
		
			_alast := FWUsrUltLog(_ausers[_nni][2])

      aAdd(	_alista,{ _ausers[_nni][4],;		
										 _ausers[_nni][3],;
										 _ausers[_nni][5],;
										 _ausers[_nni][6],;
										 _ausers[_nni][7],;
										DToC(_alast[1]),;
										_alast[2],;
										_alast[3],;
										_alast[4],;
										_alast[5]	})  	                    
Next

Return !Len(_aLista) > 0
