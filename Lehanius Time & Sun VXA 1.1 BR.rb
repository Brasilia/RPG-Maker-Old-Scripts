#==============================================================================#
# Lehanius Time & Sun VXA.1.1 BR
#------------------------------------------------------------------------------#
# Autor: Lehanius
#
# Data: d/m 06/01/2012
#
# Contatos:
# - http://www.santuariorpgmaker.com/forum/index.php?action=profile;u=80
# - rafael_1247@hotmail.com
#
#==============================================================================#
#
#==============================================================================#
# Histórico das versões
#------------------------------------------------------------------------------#
# - vxa 1.0 04/01/2012
# - vxa 1.1 06/01/2012  <> corrige tonalização da batalha
#                       <> corrige transição para interiores 
#==============================================================================#
#
#==============================================================================#
# Créditos - Credits
#------------------------------------------------------------------------------#
# - Kylock também tem créditos por este script, pois alguns dos seus métodos
# marginais (fora da engine central) foram copiados (alguns modificados) do seu
# script de tempo - Kylock's Time System - para o RPG Maker VX.
# Além disso, seu script me ajudou muito durante o processo de criação, pois me 
# deu uma boa visão geral do sistema.
#
# - Kylock also has credits for this script, as some of the marginal (out of the
# core engine) methods were taken (some modified) from Kylock's Time System for 
# RPG Maker VX.
# Also, his script helped me very much during the creation process as it gave 
# me some insights about the system as a whole.
#==============================================================================#
#
#==============================================================================#
# Termos de Uso - Terms of Use
#------------------------------------------------------------------------------#
#   - IMPORTANTE:                                                      
#   * Este script pode ser utilizado livremente para projetos pessoais,
# porém peço os devidos créditos ao autor.
#   * Se modificado, este script não deve ser distribuído sem que se
# explicite que ele foi alterado.
#   * Não remova nem altere os comentários do cabeçalho deste script,
# mesmo se o código for alterado. Quando for esse o caso, indique a
# alteração abaixo destes comentários.
#   * Se encontrar algum bug, por favor me informe por um dos contatos acima.                                                        
#                                                                      
#   - NOTICE:                                                          
#   * This script may be used for private projects, though the author  
# should be credited properly.                                         
#   * If you wish to modify and distribute this script, please make    
#  sure to inform that it has been modified.                           
#   * Do not remove or change the contents of these header comments.   
# If you have modified the script, please state it below this header.  
#   * If you find any bugs, please contact me by email or by the forum.
#==============================================================================#

=begin
#==============================================================================#
# Descrição
#------------------------------------------------------------------------------#
    Um sistema de tempo e de tonalização da tela que simula a iluminação solar,
  que varia durante todo o dia de forma contínua.
  
    Ele permite que se editem os períodos do dia e que se estabeleça uma
  tonalidade para o fim de cada período. Os tons dos tempos intermediários dos
  períodos são o tom médio (de forma ponderada) entre o tom final do período 
  anterior e o tom final do período atual, dando uma sensação de continuidade.
  
    Há a opção de se estabelecer uma tonalidade ambiente que será mesclada com
  a tonalidade solar, permitindo efeitos de iluminação solar diferentes para 
  cada mapa.
#==============================================================================#
#
#==============================================================================#
# Instruções
#------------------------------------------------------------------------------#
  - Defina as variáveis de jogo que serão usadas
  
  - Configure a definição dos períodos
  
  - Rode um evento comum em processo paralelo que incremente continuamente a 
  variável de número escolhido pela TIME_VARIABLE_ID. Insira também um comando 
  de Esperar para ajustar o tempo que irá demorar para passar cada minuto, como
  no exemplo:
      <>Esperar: 59 frames
      <>Opções de Variável: [0001:TEMPO] += 1
      (Isso fará com que se passe um minuto no jogo a cada 60 frames)
      
  - Cada mapa em que desejar usar o efeito de iluminação solar deve ter [OUT] no
  seu nome. Se desejar usar também o efeito de iluminação ambiente, simulando 
  um ambiente parcialmente fechado, use [POUT] no nome do mapa e acrescente um 
  comando de mudar tonalidade do mapa em um evento em processo paralelo.
  
  - A hora do dia ficará armazenada na variável de jogo de ID igual a 
  HOUR_VARIABLE_ID, caso queira usar condições que dependam da hora do dia.
#==============================================================================#
=end

#==============================================================================#
# ⊕ Config - Edite estes valores para configurar o sistema
#------------------------------------------------------------------------------#
module LTS
  #--------------------------------------------------------------------------
  # ! Escolha as variáveis de jogo que serão utilizadas pelo sistema !
  #--------------------------------------------------------------------------
  # Tempo do dia em minutos; controlado por evento comum
  TIME_VARIABLE_ID = 1
  # Tempo do tia em horas; controlado pelo sistema (apenas para leitura)
  HOUR_VARIABLE_ID = 2 # Você pode deixá-la como nil, caso não queira usá-la
  #--------------------------------------------------------------------------
  # Mostrar relógio no mapa
  #--------------------------------------------------------------------------
  DISPLAY_TIME = false
  #--------------------------------------------------------------------------
  # Definição dos períodos e de seus respectivos tons
  #
  # - p[x][0] -> hora inicial do período X
  # - p[x][1] -> hora final do período X
  # - p[x][0] -> tom final do período X
  #
  # - Os valores iniciais e finais dos períodos podem ir de 0 a 24
  # - Verifique se a hora final do período anterior corresponde à hora inicial
  # do período atual (0 e 24 são equivalentes)
  # - Você pode adicionar ou remover períodos, apenas siga a mesma lógica
  #--------------------------------------------------------------------------
  def self.periods
    p =[]
    p[0] = [21, 24, [-160,-160, -90,68]] 
    p[1] = [0 ,  5, [-160,-160, -90,68]]
    p[2] = [5 ,  7, [ -65, -90, -36, 0]]
    p[3] = [7 , 12, [  20,  12,  -8, 0]]
    p[4] = [12, 17, [ -10, -30, -60, 0]]
    p[5] = [17, 20, [ -90,-130,-115, 0]]
    p[6] = [20, 21, [-160,-160, -90,68]] 
    for period in p
      period[0]*=60
      period[1]*=60
    end
    return p
  end
end
#------------------------------------------------------------------------------#
# END Config
#==============================================================================#
#==============================================================================#
# Lehanius Time System Core Engine
#------------------------------------------------------------------------------#
class Lehanius_Time_System
  #--------------------------------------------------------------------------
  # Sets the flag false for event started tone changes and loads map info
  #--------------------------------------------------------------------------
  def initialize
    $lts_map_data = load_data("Data/MapInfos.rvdata2")
    $lts_event_tone = false
  end
  #--------------------------------------------------------------------------
  # Updates the time system
  #--------------------------------------------------------------------------
  def update
    return if $BTEST
    @time = $game_variables[LTS::TIME_VARIABLE_ID]
    if @time >= 1440
      @time %= 1440
    end
    @hour = @time/60
    @minute = @time%60
    $game_variables[LTS::HOUR_VARIABLE_ID] = @hour unless LTS::HOUR_VARIABLE_ID == nil
    $lts_time = sprintf("%02d:%02d", @hour, @minute)
    if $lts_event_tone
      update_tone(0) if $lts_map_data[$game_map.map_id].part_outside?
    else
      $game_map.screen.start_tone_change(Tone.new(0,0,0,0),0)
      update_tone(0) if $lts_map_data[$game_map.map_id].outside?
    end
  end
  #--------------------------------------------------------------------------
  # Updates the screen tone
  #--------------------------------------------------------------------------
  def update_tone(t)
    p = LTS::periods
    for i in 0...p.size
      if @time >= p[i][0] && @time < p[i][1]
        dt1 = @time-p[i][0]
        dt2 = p[i][1]-@time
        r = (p[i-1][2][0]*dt2+p[i][2][0]*dt1)/(dt1+dt2)
        g = (p[i-1][2][1]*dt2+p[i][2][1]*dt1)/(dt1+dt2)
        b = (p[i-1][2][2]*dt2+p[i][2][2]*dt1)/(dt1+dt2)
        gray = (p[i-1][2][3]*dt2+p[i][2][3]*dt1)/(dt1+dt2)
      end
    end
    $lts_tone = Tone.new(r, g, b, gray)
    merge_tones if $lts_map_data[$game_map.map_id].part_outside?
    $game_map.screen.start_tone_change($lts_tone, t)
  end
  #--------------------------------------------------------------------------
  # Merges sunlight tone with environment tone
  #--------------------------------------------------------------------------
  def merge_tones
    r = ($lts_tone.red + $lts_environment_tone.red)
    g = ($lts_tone.green + $lts_environment_tone.green)
    b = ($lts_tone.blue + $lts_environment_tone.blue)
    gray = ($lts_tone.gray + $lts_environment_tone.gray)
    $lts_tone = Tone.new(r, g, b, gray)
  end
end
#------------------------------------------------------------------------------#
# END Lehanius Time System Core Engine
#==============================================================================#
#==============================================================================#
# Command 223 (Change Tone)
#------------------------------------------------------------------------------#
class Game_Interpreter
  #--------------------------------------------------------------------------
  # Sets flag to disable auto tone change
  # Aborts event tone change and gets environment tone if partially outdoors 
  #--------------------------------------------------------------------------
  alias lts_command_223 command_223
  def command_223
    $lts_event_tone = true
    if $lts_map_data[$game_map.map_id].part_outside?
      $lts_environment_tone = @params[0]
      $lts.update
      return true
    end
    lts_command_223
  end
end
#------------------------------------------------------------------------------#
# END Command 223 (Change Tone)
#==============================================================================#
#==============================================================================#
# RPG::MapInfo - to check map name for outdoors flag
#------------------------------------------------------------------------------#
class RPG::MapInfo
  #--------------------------------------------------------------------------
  # self.name returns map name without brackets and its contents
  #--------------------------------------------------------------------------
  def name
    return @name.gsub(/\[.*\]/) {""}
  end
  #--------------------------------------------------------------------------
  # Returns the map's original name
  #--------------------------------------------------------------------------
  def original_name
    return @name
  end
  #--------------------------------------------------------------------------
  # Checks the outdoors flag
  #--------------------------------------------------------------------------
  def outside?
    return @name.scan(/\[OUT\]/).size > 0
  end
  #--------------------------------------------------------------------------
  # Checks the partially-outdoors flag
  #--------------------------------------------------------------------------
  def part_outside?
    return @name.scan(/\[POUT\]/).size > 0
  end
end
#------------------------------------------------------------------------------#
# END RPG::MapInfo
#==============================================================================#
#==============================================================================#
# Game_System - Time System integration to Game System
#------------------------------------------------------------------------------#
class Game_Timer
  #--------------------------------------------------------------------------
  # Initializes LTS
  #--------------------------------------------------------------------------
  alias lts_initialize initialize
  def initialize
    $lts = Lehanius_Time_System.new
    lts_initialize
  end
  #--------------------------------------------------------------------------
  # Updates LTS
  #--------------------------------------------------------------------------
  alias lts_update update
  def update
    $lts.update
    lts_update
  end
end
#------------------------------------------------------------------------------#
# END Game_System
#==============================================================================#
#==============================================================================#
# Game_Map - for instant tone change at map transition
#------------------------------------------------------------------------------#
class Game_Map
  #--------------------------------------------------------------------------
  # Makes instant tone change at map transition
  #--------------------------------------------------------------------------
  alias lts_setup setup
  def setup(map_id)
    lts_setup(map_id)
    $lts_event_tone = false
    $lts_tone = Tone.new(0, 0, 0, 0)
    $lts.update
  end
end
#------------------------------------------------------------------------------#
# END Game_Map
#==============================================================================#
#==============================================================================#
# Window_LTS - clock display window
#------------------------------------------------------------------------------#
class Window_LTS < Window_Base
  def initialize(x, y, op = 0)
    super(x, y, 96, 64)
    self.opacity = op
    refresh
  end
  def refresh
    self.contents.clear
    draw_time
  end
  def update
    super
    $lts.update
    self.contents.clear
    draw_time
  end
  def draw_time
    self.contents.draw_text(0, 0, 38, 32, $lts_time)
  end
end
#------------------------------------------------------------------------------#
# END Window_LTS
#==============================================================================#
#==============================================================================#
# Scene_Map - adds map clock if enabled
#------------------------------------------------------------------------------#
class Scene_Map < Scene_Base
  alias lts_start start
  def start
   lts_start
   @lts_window = Window_LTS.new(0,0) if LTS::DISPLAY_TIME
  end
  alias lts_terminate terminate
  def terminate
   lts_terminate
   @lts_window.dispose if @lts_window != nil
  end
  alias lts_update update
  def update
   lts_update
   @lts_window.update if @lts_window != nil
  end
end
#------------------------------------------------------------------------------#
# END Scene_Map
#==============================================================================#
