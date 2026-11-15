{%encoding utf-8}
{
translationsvmg.pas

Class which stores the translated strings

Copyright (C) 1998 - 2010 Harri Pyy, Chris O'Donnell, Felipe Monteiro de Carvalho

This file is part of Virtual Magnifying Glass.

Virtual Magnifying Glass is free software;
you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2
as published by the Free Software Foundation.

Virtual Magnifying Glass is distributed in the hope
that it will be useful, but WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE. See the GNU General Public License for more details.

Please note that the General Public License version 2 does not permit
incorporating Virtual Magnifying Glass into proprietary
programs.

AUTHORS: Chris O'Donnell, Felipe Monteiro de Carvalho and Harri Pyy
}
unit translationsvmg;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

{$IFDEF Win32}
  {$DEFINE Windows}
{$ENDIF}

interface

uses
  Classes, SysUtils, constants;

type
  { TTranslations }

  TTranslations = class(TObject)
  public
    { Menu strings }
    lpExit, lpCancel, lpAbout, lpHomepage, lpSave,
     lpDynamicMode, lpInvertColors, lpConfigDialog,
     lpGraphicalBorder, lpTools, lpMagnification, lpHeight,
     lpWidth, lpActivate, lpActivateDockedGlass, lpTranslations, lpYes, lpNo,
     lpAntiAliasing, lpHelp, lpClosePlugin: string;
    { About box strings }
    lpSupport, lpSupportInfo, lpLicense, lpLicenseInfo, lpAuthors,
     lpContributorsTitle, lpAboutWindow, lpClose, lpInformation: string;
    { Configurations dialog strings }
    lpConfigDialogTitle, lpAutoRun, lpHotKeyInvoke, lpShowWhenExecuted,
     lpTabGeneral, lpTabPlugins, lpTabHotKey, lpChoosePlugin,
     lpHotKeyDisableAll, lpHotKeyDisableInvoke, lpHotKeyCtrlAltKey, lpHotKeyKey, lpDisabledHint,
     lpShowDockedWhenExecuted, lpShowDockedWhenLensHides, lpHideDockedWhenLensShows: string;
    { Graphical tools }
    lpGTMouse, lpGTX, lpGTY: string;
    { Start Window }
    lpStartWindowText, lpClassicModeBtn, lpDynamicModeBtn: string;
    { Methods }
    procedure TranslateToEnglish;
    procedure TranslateToPortuguese;
    procedure TranslateToSpanish;
    procedure TranslateToFrench;
    procedure TranslateToGerman;
    procedure TranslateToItalian;
    procedure TranslateToRussian;
    procedure TranslateToPolish;
    procedure TranslateToJapanese;
    procedure TranslateToTurkish;
    procedure TranslateToChinese;
    procedure UpdateTranslations;
    procedure TranslateToLanguage(ALanguageID: Integer);
  end;

var
  vTranslations: TTranslations;

implementation

{$ifndef fpc}
uses Windows;
{$endif}

{ TTranslations }

{*******************************************************************
*  TTranslations.TranslateToEnglish ()
*
*  DESCRIPTION:    Translates the user interface strings to english
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TTranslations.TranslateToEnglish;
begin
  { Menu strings }
  lpExit := '&Exit';
  lpCancel := 'Cancel';
  lpAbout := 'About Virtual Magnifying Glass';
  lpHomepage := '&Visit the Magnifying Glass homepage...';
  lpSave := 'Save current settings as &default';
  lpDynamicMode :=
    {$IFDEF USE_PLUGINS}'Use Plugin (Usually Dynamic Mode)'{$ELSE}
    'Dynamic Mode'{$ENDIF};
  lpInvertColors := 'Invert Colors';
  lpConfigDialog := '&Configurations Dialog';
  lpGraphicalBorder := 'Graphical Border';
  lpTools := 'Graphics &Tools';
  lpMagnification := '&Magnification';
  lpHeight := 'Lens &height in pixels';
  lpWidth := 'Lens &width in pixels';
  lpActivate := '&Show Magnifying Glass...';
  lpActivateDockedGlass := 'Show Docked &Glass';
  lpTranslations := 'Translations';
  lpYes := 'Yes';
  lpNo := 'No';
  lpAntiAliasing := 'Anti-Aliasing';
  lpHelp := 'Help';
  lpClosePlugin  := 'Close Plugin';

  { About box strings }
  lpAboutWindow := 'About the magnifier';
  lpClose := 'Close';
  lpSupport := 'Support:';
  lpSupportInfo := 'University of Sao Paulo';
  lpLicense := 'License:';
  lpLicenseInfo := 'This software is distributed as "Free Software" under ' +
   'the terms of the GNU General Public Licence Version 2. This gives you ' +
   'the right to copy, distribute and/or modify this software under certain conditions.';
  lpAuthors := 'Authors:';
  lpContributorsTitle := 'Other Contributors:';
  lpInformation := 'Official website: http://magnifier.sourceforge.net';

  { Configurations dialog strings }
  lpConfigDialogTitle := 'Configurations Dialog';
  lpAutoRun := 'Start Magnifying Glass when you log on';
  lpHotKeyInvoke := 'Hot Key operation mode';
  lpShowWhenExecuted := 'Auto-Show when executed';
  lpTabGeneral := 'General';
  lpTabPlugins := 'Plugins';
  lpTabHotKey := 'Hot Key';
  lpChoosePlugin := 'Please choose the default plugin:';
  lpHotKeyDisableAll := 'Disable Ctrl+Alt+A,S,D,W,Key';
  lpHotKeyDisableInvoke := 'Disable Hot Key Invoke';
  lpHotKeyCtrlAltKey := 'Control+Alt+Key';
  lpHotKeyKey := 'Please choose the Key to be used in the Hot Key mode Control+Alt+Key:';
  lpDisabledHint := 'Note: The disabled items are not supported in this platform';
  lpShowDockedWhenExecuted := 'Auto-Show docked glass when executed';
  lpShowDockedWhenLensHides := 'Auto-Show docked glass when lens hides';
  lpHideDockedWhenLensShows := 'Hide docked glass when lens is shown';

  { Graphical tools }
  lpGTMouse := 'Mouse';
  lpGTX := 'X';
  lpGTY := 'Y';

  { Start Window }
  lpStartWindowText :=
    'Welcome to the Virtual Magnifying Glass. ' +
    'Please choose how you would like to use it. ' +
    'There are two options: Classic Mode or Dynamic Mode. ' +
    'In the Classic Mode the glass can be moved with the mouse and ' +
    'it will be closed when one clicks anything. ' +
    'In the Dynamic Mode, one can use the keyboard and mouse ' +
    'at the same time that the glass amplifies part of the screen. ' +
    'In this mode the Glass can only be moved using keyboard shortcuts, ' +
    'such as Ctrl+Alt+Arrows or Ctrl+Alt+A,S,D,W. ' +
    'One can change this option later in the system tray menu.';
  lpClassicModeBtn := 'Classic Mode';
  lpDynamicModeBtn := 'Dynamic Mode';
end;

{*******************************************************************
*  TTranslations.TranslateToPortuguese ()
*
*  DESCRIPTION:    Translates the user interface strings to portuguese
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TTranslations.TranslateToPortuguese;
begin
  { Menu strings }
  lpExit := '&Sair';
  lpCancel := 'Cancelar';
  lpAbout := 'Sobre a lupa digital';
  lpHomepage := '&Visite a página da lupa...';
  lpSave := 'Salvar as configurações atuais como &padrão';
  lpDynamicMode :=
    {$IFDEF USE_PLUGINS}'Usar Plugin (Normalmente Modo Dinâmico)'{$ELSE}
    'Modo Dinâmico'{$ENDIF};
  lpInvertColors := 'Inverter Cores';
  lpConfigDialog := 'Diálogo de &Configurações';
  lpGraphicalBorder := 'Mostrar &Borda Gráfica';
  lpTools := 'Ferramentas Gráficas';
  lpMagnification := '&Ampliação';
  lpHeight := 'Altura da lupa em pixels';
  lpWidth := '&Largura da lupa em pixels';
  lpActivate := 'Abrir a Lupa Digital';
  lpTranslations := 'Traduções';
  lpYes := 'Sim';
  lpNo := 'Não';
  lpAntiAliasing := 'Anti-Aliasing';
  lpHelp := 'Ajuda';
  lpClosePlugin  := 'Fechar Plugin';

  { About box strings }
  lpAboutWindow := 'Sobre a Lupa Digital';
  lpClose := 'Fechar';
  lpSupport := 'Suporte:';
  lpSupportInfo := 'Universidade de São Paulo';
  lpLicense := 'Licença:';
  lpLicenseInfo := 'Este software é distribuído como "Software Livre" pelos ' +
   'termos da licença GPL (GNU General Public Licence) Versão 2. Isto lhe dá ' +
   'o direito de copiar, distribuir e modificar este programa com certas restrições.';
  lpAuthors := 'Autores:';
  lpContributorsTitle := 'Outras Contribuições:';
  lpInformation := 'Página oficial: http://magnifier.sourceforge.net';

  { Configurations dialog strings }
  lpConfigDialogTitle := 'Diálogo de Configurações';
  lpAutoRun := 'Iniciar automaticamente a lupa com o sistema';
  lpHotKeyInvoke := 'Modo de operação da tecla de atalho';
  lpShowWhenExecuted := 'Mostrar automaticamente quando executado';
  lpTabGeneral := 'Geral';
  lpTabPlugins := 'Plugins';
  lpTabHotKey := 'Tecla de Atalho';
  lpChoosePlugin := 'Favor escolher o plugin padrão:';
  lpHotKeyDisableAll := 'Desabilitar Ctrl+Alt+A,S,D,W,Tecla';
  lpHotKeyDisableInvoke := 'Desabilitar a tecla de atalho';
  lpHotKeyCtrlAltKey := 'Control+Alt+Tecla';
  lpHotKeyKey := 'Favor escolher a tecla para ser utilizada no modo de atalho Control+Alt+Tecla:';
  lpDisabledHint := 'Obs: Os itens desabilitados não são suportados nesta plataforma';

  { Graphical tools }
  lpGTMouse := 'Mouse';
  lpGTX := 'X';
  lpGTY := 'Y';
end;

{*******************************************************************
*  TTranslations.TranslateToSpanish ()
*
*  DESCRIPTION:    Translates the user interface strings to spanish
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TTranslations.TranslateToSpanish;
begin
  { Menu strings }
  lpExit := '&Salir';
  lpCancel := 'Cancelar';
  lpAbout := 'Acerca de Virtual Magnifying Glass';
  lpHomepage := '&Visitar el sitio web...';
  lpSave := '&Guardar config. actual por defecto';
  lpDynamicMode :=
    {$IFDEF USE_PLUGINS}'Usar plugin (Normalmente modo dinámico)'{$ELSE}
    'Modo Dinámico'{$ENDIF};
  lpInvertColors := 'Invertir &colores';
  lpConfigDialog := 'Diálogo de &configuraciones';
  lpGraphicalBorder := '&Borde gráfico';
  lpTools := '&Herramientas gráficas';
  lpMagnification := '&Ampliación';
  lpHeight := 'A&ltura del lente en pixeles';
  lpWidth := 'A&ncho del lente en pixeles';
  lpActivate := '&Mostrar Magnifying Glass';
  lpTranslations := 'Traducciones';
  lpYes := 'Sí';
  lpNo := 'No';
  lpAntiAliasing := 'Anti-Aliasing';
  lpHelp := 'Ayuda';
  lpClosePlugin  := 'Cerrar plugin';

  { About box strings }
  lpAboutWindow := 'Sobre el lente';
  lpClose := 'Cerrar';
  lpSupport := 'Soporte:';
  lpSupportInfo := 'Universidad de Sao Paulo';
  lpLicense := 'Licencia:';
  lpLicenseInfo := 'Este programa se distribuye como "Software Libre" bajo ' +
   'los términos de la Licencia General Pública GNU Versión 2. Ésta le brinda ' +
   'el derecho de copiar, distribuir y/ó modificar este programa bajo ciertas condiciones.';
  lpAuthors := 'Autores:';
  lpContributorsTitle := 'Otros contribuyentes:';
  lpInformation := 'Sitio oficial: http://magnifier.sourceforge.net';

  { Configurations dialog strings }
  lpConfigDialogTitle := 'Diálogo de configuraciones';
  lpAutoRun := 'Ejecutar Magnifying Glass al iniciar el sistema';
  lpHotKeyInvoke := 'Modo de operación de teclas rápidas';
  lpShowWhenExecuted := 'Auto-mostrar al ejecutar';
  lpTabGeneral := 'General';
  lpTabPlugins := 'Extensiones';
  lpTabHotKey := 'Tecla rápida';
  lpChoosePlugin := 'Por favor seleccione el plugin por defecto:';
  lpHotKeyDisableAll := 'Deshabilitar Ctrl+Alt+A,S,D,W,Key';
  lpHotKeyDisableInvoke := 'Deshabilitar Ctrl+Alt+Key';
  lpHotKeyCtrlAltKey := 'Control+Alt+Tecla';
  lpHotKeyKey := 'Por favor seleccione la tecla a ser usada en el modo de tecla rápida Control+Alt+Tecla:';
  lpDisabledHint := 'Note: The disabled items are not supported in this platform';

  { Graphical tools }
  lpGTMouse := 'Mouse';
  lpGTX := 'X';
  lpGTY := 'Y';
end;

{*******************************************************************
*  TTranslations.TranslateToFrench ()
*
*  DESCRIPTION:    Translates the user interface strings to french
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TTranslations.TranslateToFrench;
begin
  { Menu strings }
  lpExit := '&Fermer';
  lpCancel := 'A&nnuler';
  lpAbout := 'A propos de Virtual Magnifying Glass';
  lpHomepage := '&Visitez la page web de Magnifying Glass';
  lpSave := '&Sauvegardez les réglages actuels en tant que défaut';
  lpDynamicMode := ' Mode Dynamique';
  lpInvertColors := 'Inverser les Couleurs';
  lpConfigDialog := 'Dialogue de Configuration';
  lpGraphicalBorder := 'Bordure Graphique';
  lpTools := '&Outils Graphiques';
  lpMagnification := '&Grossissement';
  lpHeight := '&Hauteur de la loupe en pixels';
  lpWidth := '&Largeur de la loupe en pixels';
  lpActivate := '&Activer la loupe';
  lpTranslations := 'Traductions';
  lpYes := 'Oui';
  lpNo := 'Non';
  lpAntiAliasing := 'Anti-Aliasing';
  lpHelp := 'Aide';
  lpClosePlugin  := 'Fermer Plugin';

  { About box strings }
  lpAboutWindow := 'A propos de la loupe';
  lpClose := 'Fermer';
  lpSupport := 'Support:';
  lpSupportInfo := 'Université de Sao Paulo';
  lpLicense := 'License:';
  lpLicenseInfo := 'Ce logiciel est distribué comme "Logiciel Gratuit" sous' +
   'les termes de  Licence Publique General GNU Version 2. Ceci vous donne ' +
   'le droit de copier, distribuer et/ou modifier ce logiciel sous certaines conditions.';
  lpAuthors := 'Auteurs:';
  lpContributorsTitle := 'Autres Contributeurs:';
  lpInformation := 'site web officiel: http://magnifier.sourceforge.net';

  { Configurations dialog strings }
  lpConfigDialogTitle := 'Dialogue de Configuration';
  lpAutoRun := 'Lançer Magnifying Glass au démarrage';
  lpHotKeyInvoke := 'Raccourci clavier';
  lpShowWhenExecuted := 'Afficher une fois lançé';
  lpTabGeneral := 'General';
  lpTabPlugins := 'Plugins';
  lpTabHotKey := 'Raccourci clavier';
  lpChoosePlugin := 'Prière de choisir le plug-in par défaut:';
  lpHotKeyDisableAll := 'Désactivé Ctrl+Alt+A,S,D,W,Touche';
  lpHotKeyDisableInvoke := 'Désactivé Ctrl+Alt+Touche';
  lpHotKeyCtrlAltKey := 'Control+Alt+Touche';
  lpHotKeyKey := 'Prière de choisir la touche à utiliser en raccourci clavier, mode Control+Alt+Touche:';
  lpDisabledHint := 'les éléments déactivés ne sont pas supportés sur cette plate forme';

  { Graphical tools }
  lpGTMouse := 'Souris';
  lpGTX := 'X';
  lpGTY := 'Y';
end;

{*******************************************************************
*  TTranslations.TranslateToGerman ()
*
*  DESCRIPTION:    Translates the user interface strings to german
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TTranslations.TranslateToGerman;
begin
  { Menu strings }
  lpExit := 'B&eenden';
  lpCancel := '&Abbruch';
  lpAbout := '&Über Virtual Magnifying Glass';
  lpHomepage := 'Besuche die &Magnifying Glass Homepage...';
  lpSave := 'Speichere die aktuellen Einstellungen als &Default';
  lpDynamicMode := 'Dynamischer M&odus';
  lpInvertColors := '&Invertiere Farben';
  lpConfigDialog := '&Konfiguration';
  lpGraphicalBorder := 'Grafischer &Rahmen';
  lpTools := 'Grafische &Tools';
  lpMagnification := '&Vergrößerungsfaktor';
  lpHeight := 'Lupen&höhe in pixel';
  lpWidth := 'Lupen&breite in pixel';
  lpActivate := '&Zeige Vergrößerungsglas...';
  lpTranslations := 'Übersetzungen';
  lpYes := '&Ja';
  lpNo := '&Nein';
  lpAntiAliasing := 'Anti-A&liasing';
  lpHelp := '&Hilfe';
  lpClosePlugin  := 'Beende den &Plugin';

  { About box strings }
  lpAboutWindow := 'Über Virtual Magnifying Glass';
  lpClose := 'Schließen';
  lpSupport := 'Support:';
  lpSupportInfo := 'Universität von São Paulo';
  lpLicense := 'Lizenz:';
  lpLicenseInfo := 'Dieses Programm wurde als "Freie Software" unter ' +
   'den Bedingungen der GNU General Public Licence Version 2. Unter bestimmten ' +
   'Bedingungen haben Sie das Recht es zu kopieren, weitergeben und/oder zu modifizieren.';
  lpAuthors := 'Autoren:';
  lpContributorsTitle := 'Andere Mitarbeiter:';
  lpInformation := 'Offiziele Webseite: http://magnifier.sourceforge.net';

  { Configurations dialog strings }
  lpConfigDialogTitle := 'Konfigurationsdialoge';
  lpAutoRun := 'Starte Magnifying Glass beim Starten von Windows';
  lpHotKeyInvoke := 'Tastenkürzelfunktion';
  lpShowWhenExecuted := 'Auto-Zeigen wenn ausführt';
  lpTabGeneral := 'Allgemein';
  lpTabPlugins := 'Plugins';
  lpTabHotKey := 'Tastenkürzel';
  lpChoosePlugin := 'Bitte wählen Sie einen Standardplugin:';
  lpHotKeyDisableAll := 'Deaktivieren Strg+Alt+A,S,D,W,Taste';
  lpHotKeyDisableInvoke := 'Deaktivieren Strg+Alt+Taste';
  lpHotKeyCtrlAltKey := 'Strg+Alt+Taste';
  lpHotKeyKey := 'Bitte wählen Sie eine Taste für die Tastenkürzelfunktion Strg+Alt+Taste:';
  lpDisabledHint := 'Hinweis: Die deaktivierten Elemente werden auf dieser Plattform nicht unterstützt';

  { Graphical tools }
  lpGTMouse := 'Maus';
  lpGTX := 'X';
  lpGTY := 'Y';
end;

{*******************************************************************
*  TTranslations.TranslateToItalian ()
*
*  DESCRIPTION:    Translates the user interface strings to italian
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TTranslations.TranslateToItalian;
begin
  { Menu strings }
  lpExit := '&Uscita';
  lpCancel := 'Cancella';
  lpAbout := 'Informazioni su Virtual Magnifying Glass';
  lpHomepage := '&Visita l''homepage di Magnifying Glass...';
  lpSave := 'Salva i settaggi correnti come &default';
  lpDynamicMode :=
    {$IFDEF USE_PLUGINS}'Usa Plugin (Normalmente Dynamic Mode)'{$ELSE}
    'Dynamic Mode'{$ENDIF};
  lpInvertColors := 'Colori Invertiti';
  lpConfigDialog := 'Dialogo di &Configurazioni';
  lpGraphicalBorder := 'Bordo Grafico';
  lpTools := '&Tools grafiche';
  lpMagnification := '&Ingrandimento';
  lpHeight := '&Altezza della lente in pixel';
  lpWidth := '&Larghezza della lente in pixel';
  lpActivate := '&Mostra la lente...';
  lpTranslations := 'Traduzioni';
  lpYes := 'Si';
  lpNo := 'No';
  lpAntiAliasing := 'Anti-Aliasing';
  lpHelp := 'Aiuto';
  lpClosePlugin  := 'Chiudi Plugin';

  { About box strings }
  lpAboutWindow := 'About the magnifier';
  lpClose := 'Chiudi';
  lpSupport := 'Support:';
  lpSupportInfo := 'University of Sao Paulo';
  lpLicense := 'Licenza:';
  lpLicenseInfo := 'Questo Software è distribuito come "Free Software" sotto ' +
   'il termine di GNU General Public Licence Version 2. Questo da il diritto'+
   'di copiare, distribuirlo e/o modificare questo software sotto stabilite condizioni.';
  lpAuthors := 'Autori:';
  lpContributorsTitle := 'Altri Contributori:';
  lpInformation := 'Per altre informazioni visita il nostro sito: http://magnifier.sourceforge.net';

  { Configurations dialog strings }
  lpConfigDialogTitle := 'Dialogo di Configurazioni';
  lpAutoRun := 'Avvia Magnifying Glass quanto parte il sistema';
  lpHotKeyInvoke := 'Hot Key operation mode';
  lpShowWhenExecuted := 'Mostra automaticamente quando eseguita';
  lpTabGeneral := 'General';
  lpTabPlugins := 'Plugins';
  lpTabHotKey := 'Hot Key';
  lpChoosePlugin := 'Please choose the default plugin:';
  lpHotKeyDisableAll := 'Desabilitare Control+Alt+A,S,D,W,Tasto';
  lpHotKeyDisableInvoke := 'Desabilitare Control+Alt+Tasto';
  lpHotKeyCtrlAltKey := 'Control+Alt+Tasto';
  lpHotKeyKey := 'Please choose the Key to be used in the Hot Key mode Control+Alt+Tasto:';
  lpDisabledHint := 'Obs: The disabled items are not supported in this platform';

  { Graphical tools }
  lpGTMouse := 'Mouse';
  lpGTX := 'X';
  lpGTY := 'Y';
end;

{*******************************************************************
*  TTranslations.TranslateToRussian ()
*
*  DESCRIPTION:    Translates the user interface strings to russian
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TTranslations.TranslateToRussian;
begin
  { Menu strings }
  lpExit := '&Выход';
  lpCancel := '&Отменить';
  lpAbout := 'О программе';
  lpHomepage := '&Посетить домашнию страницу Magnifying Glass...';
  lpSave := 'Загружать текущие установки по умолчанию';
  lpDynamicMode := 'Использовать плагин (Динамический режим)';
  lpInvertColors := 'Инвертировать цвета';
  lpConfigDialog := 'Диалог конфигураций';
  lpGraphicalBorder := 'Графическая граница';
  lpTools := 'Графика &Инструменты';
  lpMagnification := '&Увеличение';
  lpHeight := 'Лупа &высота в пикселях';
  lpWidth := 'Лупа &ширина в пикселях';
  lpActivate := '&Показать лупу...';
  lpTranslations := 'Переводы';
  lpYes := 'Да';
  lpNo := 'Нет';
  lpAntiAliasing := 'Сглаживание';
  lpHelp := 'Помощь';
  lpClosePlugin  := 'Закрыть плагин';

  { About box strings }
  lpAboutWindow := 'О программе';
  lpClose := 'Закрыть';
  lpSupport := 'Поддержка:';
  lpSupportInfo := 'Университет Sao Paulo';
  lpLicense := 'Лицензия:';
  lpLicenseInfo := 'Эта программа распространяется свободно в соответствии с ' +
   'лицензией GNU Версия 2. Это дает Вам право ' +
   'копировать, распространять и/или изменять данную программу в соответствии с этими условиями.';
  lpAuthors := 'Авторы:';
  lpContributorsTitle := 'Помощники:';
  lpInformation := 'За дополнительной информацией обращайтесь на сайт: http://magnifier.sourceforge.net';

  { Configurations dialog strings }
  lpConfigDialogTitle := 'Диалог конфигураций';
  lpAutoRun := 'Запускать Magnifying Glass при  загрузке системы';
  lpHotKeyInvoke := 'Hot Key operation mode';
  lpShowWhenExecuted := 'Показывать автоматически при открытии';
  lpTabGeneral := 'General';
  lpTabPlugins := 'Plugins';
  lpTabHotKey := 'Hot Key';
  lpChoosePlugin := 'Please choose the default plugin:';
  lpHotKeyDisableAll := 'Disable Control+Alt+A,S,D,W,Key';
  lpHotKeyDisableInvoke := 'Disable Control+Alt+Key';
  lpHotKeyCtrlAltKey := 'Control+Alt+Key';
  lpHotKeyKey := 'Please choose the Key to be used in the Hot Key mode Control+Alt+Key:';
  lpDisabledHint := 'Obs: The disabled items are not supported in this platform';

  { Graphical tools }
  lpGTMouse := 'Mouse';
  lpGTX := 'X';
  lpGTY := 'Y';
end;

{*******************************************************************
*  TTranslations.TranslateToPolish ()
*
*  DESCRIPTION:    Translates the user interface strings to polish
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TTranslations.TranslateToPolish;
begin
  { Menu strings }
  lpExit := 'Za&kończ';
  lpCancel := '&Anuluj';
  lpAbout := '&Informacje o Virtual Magnifying Glass';
  lpHomepage := 'Odwiedź stronę domową &Magnifying Glass...';
  lpSave := 'Zapisz aktualne ustawienia jako &Default';
  lpDynamicMode := 'Tryb d&ynamiczny';
  lpInvertColors := '&Odwróć kolory';
  lpConfigDialog := 'Kon&figuracje';
  lpGraphicalBorder := '&Ramka graficzna';
  lpTools := 'Narzędzia &graficzne';
  lpMagnification := 'Powięks&zenie';
  lpHeight := '&Wysokość szkła powiększającego w pikselach';
  lpWidth := '&Szerokość szkła powiększającego w pikselach';
  lpActivate := '&Pokaż szkło powiększające...';
  lpTranslations := 'Tłumaczenia';
  lpYes := '&Tak';
  lpNo := '&Nie';
  lpAntiAliasing := 'Anti-A&liasing';
  lpHelp := 'Pomo&c';
  lpClosePlugin := 'Zamkni&j wtyczkę';

  { About box strings }
  lpAboutWindow := 'Informacje o magnifier';
  lpClose := 'Zamknij';
  lpSupport := 'Support:';
  lpSupportInfo := 'Uniwersytet São Paulo';
  lpLicense := 'Licencja:';
  lpLicenseInfo := 'To oprogramowanie jest rozpowszechniane jako "Wolne Oprogramowanie" na ' +
   'warunkach GNU General Public Licence Version 2. Masz prawo ' +
   'do kopiowania, rozpowszechniania i/lub modyfikowania tego oprogramowania pod pewnymi warunkami.';
  lpAuthors := 'Autorzy:';
  lpContributorsTitle := 'Współpraca:';
  lpInformation := 'Oficjalna strona internetowa: http://magnifier.sourceforge.net';

  { Configurations dialog strings }
  lpConfigDialogTitle := 'Konfiguracje';
  lpAutoRun := 'Uruchamiaj Magnifying Glass przy starcie Windows';
  lpHotKeyInvoke := 'Tryb klawiszy skrótów';
  lpShowWhenExecuted := 'Pokazuj automatycznie gdy wykonano';
  lpTabGeneral := 'Ogólne';
  lpTabPlugins := 'Wtyczki';
  lpTabHotKey := 'Klawisze skrótów';
  lpChoosePlugin := 'Wybierz domyślną wtyczkę:';
  lpHotKeyDisableAll := 'Wyłączyć Control+Alt+A,S,D,W,Klawisz';
  lpHotKeyDisableInvoke := 'Wyłączyć Control+Alt+Klawisz';
  lpHotKeyCtrlAltKey := 'Control+Alt+Klawisz';
  lpHotKeyKey := 'Wybierz klawisz, który będzie używany w trybie klawisza skrótu Control+Alt+Klawisz:';
  lpDisabledHint := 'Uwaga: Wyłączone pozycje nie są obsługiwane na tej platformie';

  { Graphical tools }
  lpGTMouse := 'Myszka';
  lpGTX := 'X';
  lpGTY := 'Y';
end;

{*******************************************************************
*  TTranslations.TranslateToJapanese ()
*
*  DESCRIPTION:    Translates the user interface strings to japanese
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TTranslations.TranslateToJapanese;
begin
  { Menu strings }
  lpExit := '終了(&E)';
  lpCancel := 'キャンセル(&N)';
  lpAbout := 'Virtual Magnifying Glass 情報';
  lpHomepage := 'Magnifying Glass ホームページへ(&V)';
  lpSave := '現在の設定を保存(&D)';
  lpDynamicMode := 'ダイナミックモード（プラグイン使用）';
  lpInvertColors := 'カラー反転';
  lpConfigDialog := '設定画面を表示(&C)';
  lpGraphicalBorder := 'ボーダー表示';
  lpTools := 'グラフィックツール(&T)';
  lpMagnification := '拡大率(&M)';
  lpHeight := 'レンズの高さ：ピクセル(&H)';
  lpWidth := 'レンズの横幅：ピクセル(&W)';
  lpActivate := 'Magnifying Glass を表示(&S)';
  lpTranslations := '使用言語';
  lpYes := 'はい';
  lpNo := 'いいえ';
  lpAntiAliasing := 'アンチエリアス';
  lpHelp := 'ヘルプ';
  lpClosePlugin  := 'プラグインを終了';

  { About box strings }
  lpAboutWindow := 'Magnifier について';
  lpClose := '閉じる';
  lpSupport := 'サポート：';
  lpSupportInfo := 'Sao Paulo ユニバーシティ';
  lpLicense := 'ライセンス：';
  lpLicenseInfo := 'このソフトウェアは「GNU General Public Licence Version 2」によって' +
   '定義された「Free Software」として配布されています。ユーザーはライセンスに基づく' +
   '特定の条件下において、このソフトウェアをコピー、配布、変更する権利を与えられます。';
  lpAuthors := '作者：';
  lpContributorsTitle := '他の貢献者：';
  lpInformation := 'その他の情報は、次へ： http://magnifier.sourceforge.net';

  { Configurations dialog strings }
  lpConfigDialogTitle := 'Configurations Dialog';
  lpAutoRun := 'Magnifying Glass をスタートアップ登録';
  lpHotKeyInvoke := 'ホットキー操作';
  lpShowWhenExecuted := '起動時にレンズを表示';
  lpTabGeneral := '一般';
  lpTabPlugins := 'プラグイン';
  lpTabHotKey := 'ホットキー';
  lpChoosePlugin := 'デフォルトの使用プラグインを選択';
  lpHotKeyDisableAll := '無効 Control+Alt+A,S,D,W,指定キー';
  lpHotKeyDisableInvoke := '無効 Control+Alt+指定キー';
  lpHotKeyCtrlAltKey := 'Ctrl+Alt+ 指定キー';
  lpHotKeyKey := 'Ctrl+Alt と共に使用するキーを指定してください：';
  lpDisabledHint := 'Note: The disabled items are not supported in this platform';

  { Graphical tools }
  lpGTMouse := 'Mouse';
  lpGTX := 'X';
  lpGTY := 'Y';
end;

{*******************************************************************}
{@@
  Translates the user interface strings to turkish
}
{*******************************************************************}
procedure TTranslations.TranslateToTurkish;
begin
  { Menu strings }
  lpExit := '&Çikis';
  lpCancel := 'iptal';
  lpAbout := 'Virtual Magnifying Glass Hakkinda';
  lpHomepage := '&Magnifying Glass ana sayfasina git...';
  lpSave := '&Suanki ayarlari varsayilan yap';
  lpDynamicMode :=
    {$IFDEF USE_PLUGINS}'Eklenti Kullan (Usually Dynamic Mode)'{$ELSE}
    'Dynamic Mode'{$ENDIF};
  lpInvertColors := 'Renkleri Çevir';
  lpConfigDialog := '&Konfigürasyonlar';
  lpGraphicalBorder := 'Grafiksel Kenar';
  lpTools := '&Grafik Araçlari';
  lpMagnification := '&Büyütme';
  lpHeight := 'M&ercek yüksekligi piksel';
  lpWidth := 'Me&rcek genisligi piksel';
  lpActivate := 'B&üyüteçi Göster...';
  lpTranslations := 'Çeviriler';
  lpYes := 'Evet';
  lpNo := 'Hayir';
  lpAntiAliasing := 'Anti-Aliasing';
  lpHelp := 'Yardim';
  lpClosePlugin  := 'Eklenti Kapat';

  { About box strings }
  lpAboutWindow := 'Büyüteç Hakkinda';
  lpClose := 'Kapat';
  lpSupport := 'Destek:';
  lpSupportInfo := 'Sao Paulo Üniversitesi';
  lpLicense := 'Lisans:';
  lpLicenseInfo := 'Bu yazilim "Ücretsiz Yazilim" olarak' +
   'GNU General Public Licence Version 2 altinda dagitilir.' +
   'Kopyalanmasi, dagitilmasi, düzenlemesi sartlara baglidir.';
  lpAuthors := 'Sahipleri:';
  lpContributorsTitle := 'Diger istirakçileri:';
  lpInformation := 'Resmi website: http://magnifier.sourceforge.net';

  { Configurations dialog strings }
  lpConfigDialogTitle := 'Konfigürasyonlar';
  lpAutoRun := 'Oturum açilinca büyüteci çalistir';
  lpHotKeyInvoke := 'Kisayol Tusu operasyon modu';
  lpShowWhenExecuted := 'Çalistiginda otomatik göster';
  lpTabGeneral := 'Genel';
  lpTabPlugins := 'Eklentiler';
  lpTabHotKey := 'Kisayol Tusu';
  lpChoosePlugin := 'Varsayilan eklentiyi belirleyin:';
  lpHotKeyDisableAll := 'Etkisiz Control+Alt+A,S,D,W,Tus';
  lpHotKeyDisableInvoke := 'Etkisiz Control+Alt+Tus';
  lpHotKeyCtrlAltKey := 'Control+Alt+Tus';
  lpHotKeyKey := 'Kisayol Tusu modu Control+Alt+Tus kombinasyonunda kullanýlacak tus:';
  lpDisabledHint := 'Not: Etkisiz nesneler bu platformda desteklenmiyorlar';

  { Graphical tools }
  lpGTMouse := 'Fare';
  lpGTX := 'X';
  lpGTY := 'Y';
end;

{*******************************************************************
*  TTranslations.TranslateToChinese ()
*
*  DESCRIPTION:    Translates the user interface strings to Chinese
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TTranslations.TranslateToChinese;
begin
  { Menu strings }
  lpExit := '退出(&E)';
  lpCancel := '取消';
  lpAbout := '关于 虚拟放大镜';
  lpHomepage := '访问 虚拟放大镜主页(&V)...';
  lpSave := '保存当前设置为默认(&D)';
  lpDynamicMode :=
    {$IFDEF USE_PLUGINS}'使用插件(普通动态模式)'{$ELSE}
    '动态模式'{$ENDIF};
  lpInvertColors := '颜色反转';
  lpConfigDialog := '设置(&C)';
  lpGraphicalBorder := '图形化边框';
  lpTools := '图形工具(&T)';
  lpMagnification := '放大倍率(&M)';
  lpHeight := '透镜象素高度(&H)';
  lpWidth := '透镜象素宽度(&W)';
  lpActivate := '显示放大镜(&S)...';
  lpTranslations := '语言';
  lpYes := '是';
  lpNo := '否';
  lpAntiAliasing := '反锯齿';
  lpHelp := '帮助';
  lpClosePlugin  := '关闭插件';

  { About box strings }
  lpAboutWindow := '关于放大镜';
  lpClose := '关闭';
  lpSupport := '支持:';
  lpSupportInfo := '圣保罗大学(巴西)';
  lpLicense := '许可证:';
  lpLicenseInfo :='本程序为自由软件;您可依据自由软件基金会'+
  '所发表的GNU通用公共授权条款规定,就本程序再为复制、发布'+
  '与／或修改;无论您依据的是本授权的第二版或(您自行选择的)任一日后发行的版本.';
  lpAuthors := '作者:';
  lpContributorsTitle := '其它贡献者:';
  lpInformation := '官方网站: http://magnifier.sourceforge.net';

  { Configurations dialog strings }
  lpConfigDialogTitle := '设置';
  lpAutoRun := '当登录时启动放大镜';
  lpHotKeyInvoke := '热键操作模式';
  lpShowWhenExecuted := '执行时自动显示';
  lpTabGeneral := '常规';
  lpTabPlugins := '插件';
  lpTabHotKey := '热键';
  lpChoosePlugin := '请选择默认的插件:';
  lpHotKeyDisableAll := '禁用 Ctrl+Alt+A,S,D,W,键';
  lpHotKeyDisableInvoke := '禁用热键激活';
  lpHotKeyCtrlAltKey := 'Ctrl+Alt+键值';
  lpHotKeyKey := '请选择用于热键模式的键值 Ctrl+Alt+键值:';
  lpDisabledHint := '注意: 禁用后项目不再支持这个平台';

  { Graphical tools }
  lpGTMouse := 'Mouse';
  lpGTX := 'X';
  lpGTY := 'Y';

  { Start Window }
  lpStartWindowText :=
    '欢迎来到 虚拟放大镜.' +
    '请选择你想如何使用它.' +
    '有两个选项: 经典模式 或 动态模式' +
    '在经典模式中透镜可以随着鼠标移动并且' +
    '当单击任意处时可关闭.' +
    '在动态模式中,在透镜放大屏幕部分的同时' +
    '只能使用键盘和鼠标的一种.' +
    '在这种模式中透镜只能被键盘快捷键移动,' +
    '例如 Ctrl+Alt+方向键 或 Ctrl+Alt+A,S,D,W.' +
    '您也可以稍后在系统托盘菜单修改使用的模式.';
  lpClassicModeBtn := '经典模式';
  lpDynamicModeBtn := '动态模式';
end;

{*******************************************************************
*  TTranslations.UpdateTranslations ()
*
*  DESCRIPTION:    Under Desktop Windows, this procedure converts the
*                  UTF-8 strings to ISO 8859-1
*
*                  Under all other platforms no changes are required
*
*  PARAMETERS:     None
*
*  RETURNS:        Nothing
*
*******************************************************************}
procedure TTranslations.UpdateTranslations;

  {$ifndef fpc}
  procedure UpdateString(var AStr: string);
  var
    CharBuffer: array[0..255] of Char;
    WideBuffer: array[0..255] of WideChar;
  begin
    FillChar(CharBuffer, SizeOf(CharBuffer), #0);
    FillChar(WideBuffer, SizeOf(WideBuffer), #0);
    MultibyteToWideChar(CP_UTF8, 0, PChar(AStr), -1, @WideBuffer, 255);
    WideCharToMultibyte(CP_ACP, 0, @WideBuffer, -1, @CharBuffer, 255, nil, nil);
    AStr := PChar(@CharBuffer);
  end;
  {$endif}

begin
  {$ifndef fpc}
  { Menu strings }
  UpdateString(lpExit);
  UpdateString(lpCancel);
  UpdateString(lpAbout);
  UpdateString(lpHomepage);
  UpdateString(lpSave);
  UpdateString(lpDynamicMode);
  UpdateString(lpInvertColors);
  UpdateString(lpConfigDialog);
  UpdateString(lpGraphicalBorder);
  UpdateString(lpTools);
  UpdateString(lpMagnification);
  UpdateString(lpHeight);
  UpdateString(lpWidth);
  UpdateString(lpActivate);
  UpdateString(lpTranslations);
  UpdateString(lpYes);
  UpdateString(lpNo);
  UpdateString(lpAntiAliasing);
  UpdateString(lpHelp);
  UpdateString(lpClosePlugin);

  { About box strings }
  UpdateString(lpSupport);
  UpdateString(lpSupportInfo);
  UpdateString(lpLicense);
  UpdateString(lpLicenseInfo);
  UpdateString(lpAuthors);
  UpdateString(lpContributorsTitle);
  UpdateString(lpAboutWindow);
  UpdateString(lpClose);
  UpdateString(lpInformation);

  { Configurations dialog strings }
  UpdateString(lpConfigDialogTitle);
  UpdateString(lpAutoRun);
  UpdateString(lpHotKeyInvoke);
  UpdateString(lpShowWhenExecuted);
  UpdateString(lpTabGeneral);
  UpdateString(lpTabPlugins);
  UpdateString(lpTabHotKey);
  UpdateString(lpChoosePlugin);
  UpdateString(lpHotKeyNone);
  UpdateString(lpHotKeyCtrlAltKey);
  UpdateString(lpHotKeyKey);
  UpdateString(lpDisabledHint);

  { Graphical tools }
  UpdateString(lpGTMouse);
  UpdateString(lpGTX);
  UpdateString(lpGTY);

  { Start Window }
  UpdateString(lpStartWindowText);
  UpdateString(lpClassicModeBtn);
  UpdateString(lpDynamicModeBtn);
  {$endif}
end;

procedure TTranslations.TranslateToLanguage(ALanguageID: Integer);
begin
  case ALanguageID of
   ID_MENU_ENGLISH: TranslateToEnglish;
   ID_MENU_PORTUGUESE: TranslateToPortuguese;
   ID_MENU_SPANISH: TranslateToSpanish;
   ID_MENU_FRENCH: TranslateToFrench;
   ID_MENU_GERMAN: TranslateToGerman;
   ID_MENU_ITALIAN: TranslateToItalian;
   ID_MENU_RUSSIAN: TranslateToRussian;
   ID_MENU_POLISH: TranslateToPolish;
   ID_MENU_JAPANESE: TranslateToJapanese;
   ID_MENU_TURKISH: TranslateToTurkish;
   ID_MENU_CHINESE: TranslateToChinese;
  else
    Exit; // Error
  end;

  UpdateTranslations;
end;

{*******************************************************************
*  Initialization section
*
*  DESCRIPTION:    Initializes the translations.
*
*******************************************************************}
initialization

  vTranslations := TTranslations.Create;

{*******************************************************************
*  Finalization section
*
*  DESCRIPTION:    Free memory allocated on the initialization section
*
*******************************************************************}
finalization

  FreeAndNil(vTranslations);

end.
