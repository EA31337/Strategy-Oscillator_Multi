/**
 * @file
 * Implements Oscillator strategy based on the Oscillator indicator.
 */

enum ENUM_STG_OSCILLATOR_TYPE {
  STG_OSCILLATOR_TYPE_0_NONE = 0,  // (None)
  STG_OSCILLATOR_TYPE_AC,          // AC
  STG_OSCILLATOR_TYPE_AD,          // AD
  STG_OSCILLATOR_TYPE_RSI,         // RSI
  STG_OSCILLATOR_TYPE_STOCH,       // Stochastic
  STG_OSCILLATOR_TYPE_WPR,         // WPR
};

// User input params.
INPUT_GROUP("Oscillator strategy: main strategy params");
INPUT ENUM_STG_OSCILLATOR_TYPE Oscillator_Type = STG_OSCILLATOR_TYPE_RSI;  // Oscillator type
INPUT_GROUP("Oscillator strategy: strategy params");
INPUT float Oscillator_LotSize = 0;                // Lot size
INPUT int Oscillator_SignalOpenMethod = 6;         // Signal open method
INPUT float Oscillator_SignalOpenLevel = 0;        // Signal open level
INPUT int Oscillator_SignalOpenFilterMethod = 32;  // Signal open filter method
INPUT int Oscillator_SignalOpenFilterTime = 3;     // Signal open filter time (0-31)
INPUT int Oscillator_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT int Oscillator_SignalCloseMethod = 0;        // Signal close method
INPUT int Oscillator_SignalCloseFilter = 32;       // Signal close filter (-127-127)
INPUT float Oscillator_SignalCloseLevel = 0;       // Signal close level
INPUT int Oscillator_PriceStopMethod = 0;          // Price limit method
INPUT float Oscillator_PriceStopLevel = 2;         // Price limit level
INPUT int Oscillator_TickFilterMethod = 32;        // Tick filter method (0-255)
INPUT float Oscillator_MaxSpread = 4.0;            // Max spread to trade (in pips)
INPUT short Oscillator_Shift = 0;                  // Shift
INPUT float Oscillator_OrderCloseLoss = 80;        // Order close loss
INPUT float Oscillator_OrderCloseProfit = 80;      // Order close profit
INPUT int Oscillator_OrderCloseTime = -30;         // Order close time in mins (>0) or bars (<0)
INPUT_GROUP("Oscillator strategy: AC oscillator params");
INPUT int Oscillator_Indi_AC_Shift = 0;                                      // Shift
INPUT ENUM_IDATA_SOURCE_TYPE Oscillator_Indi_AC_SourceType = IDATA_BUILTIN;  // Source type
INPUT_GROUP("Oscillator strategy: AD oscillator params");
INPUT int Oscillator_Indi_AD_Shift = 0;                                      // Shift
INPUT ENUM_IDATA_SOURCE_TYPE Oscillator_Indi_AD_SourceType = IDATA_BUILTIN;  // Source type
INPUT_GROUP("Oscillator strategy: RSI indicator params");
INPUT int Oscillator_Indi_RSI_Period = 16;                                    // Period
INPUT ENUM_APPLIED_PRICE Oscillator_Indi_RSI_Applied_Price = PRICE_WEIGHTED;  // Applied Price
INPUT int Oscillator_Indi_RSI_Shift = 0;                                      // Shift
INPUT_GROUP("Oscillator strategy: Stochastic indicator params");
INPUT int Oscillator_Indi_Stochastic_KPeriod = 8;                      // K line period
INPUT int Oscillator_Indi_Stochastic_DPeriod = 12;                     // D line period
INPUT int Oscillator_Indi_Stochastic_Slowing = 12;                     // Slowing
INPUT ENUM_MA_METHOD Oscillator_Indi_Stochastic_MA_Method = MODE_EMA;  // Moving Average method
INPUT ENUM_STO_PRICE Oscillator_Indi_Stochastic_Price_Field = 0;       // Price (0 - Low/High or 1 - Close/Close)
INPUT int Oscillator_Indi_Stochastic_Shift = 0;                        // Shift
INPUT_GROUP("Oscillator strategy: WPR indicator params");
INPUT int Oscillator_Indi_WPR_Period = 18;  // Period
INPUT int Oscillator_Indi_WPR_Shift = 0;    // Shift

// Structs.

// Defines struct with default user strategy values.
struct Stg_Oscillator_Params_Defaults : StgParams {
  Stg_Oscillator_Params_Defaults()
      : StgParams(::Oscillator_SignalOpenMethod, ::Oscillator_SignalOpenFilterMethod, ::Oscillator_SignalOpenLevel,
                  ::Oscillator_SignalOpenBoostMethod, ::Oscillator_SignalCloseMethod, ::Oscillator_SignalCloseFilter,
                  ::Oscillator_SignalCloseLevel, ::Oscillator_PriceStopMethod, ::Oscillator_PriceStopLevel,
                  ::Oscillator_TickFilterMethod, ::Oscillator_MaxSpread, ::Oscillator_Shift) {
    Set(STRAT_PARAM_LS, Oscillator_LotSize);
    Set(STRAT_PARAM_OCL, Oscillator_OrderCloseLoss);
    Set(STRAT_PARAM_OCP, Oscillator_OrderCloseProfit);
    Set(STRAT_PARAM_OCT, Oscillator_OrderCloseTime);
    Set(STRAT_PARAM_SOFT, Oscillator_SignalOpenFilterTime);
  }
};

class Stg_Oscillator : public Strategy {
 public:
  Stg_Oscillator(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_Oscillator *Init(ENUM_TIMEFRAMES _tf = NULL, EA *_ea = NULL) {
    // Initialize strategy initial values.
    Stg_Oscillator_Params_Defaults stg_oscillator_defaults;
    StgParams _stg_params(stg_oscillator_defaults);
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams;
    Strategy *_strat = new Stg_Oscillator(_stg_params, _tparams, _cparams, "Oscillator");
    return _strat;
  }

  /**
   * Validate soscillators's entry.
   */
  bool IsValidEntry(IndicatorBase *_indi, int _shift = 0) {
    bool _result = true;
    switch (Oscillator_Type) {
      case STG_OSCILLATOR_TYPE_AC:
        _result &= dynamic_cast<Indi_AC *>(_indi).GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift) &&
                   dynamic_cast<Indi_AC *>(_indi).GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift + 1);
        break;
      case STG_OSCILLATOR_TYPE_AD:
        _result &= dynamic_cast<Indi_AD *>(_indi).GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift) &&
                   dynamic_cast<Indi_AD *>(_indi).GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift + 1);
        break;
      case STG_OSCILLATOR_TYPE_RSI:
        _result &= dynamic_cast<Indi_RSI *>(_indi).GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift) &&
                   dynamic_cast<Indi_RSI *>(_indi).GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift + 1);
        break;
      case STG_OSCILLATOR_TYPE_STOCH:
        _result &= dynamic_cast<Indi_Stochastic *>(_indi).GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift) &&
                   dynamic_cast<Indi_Stochastic *>(_indi).GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift + 1);
        break;
      case STG_OSCILLATOR_TYPE_WPR:
        _result &= dynamic_cast<Indi_WPR *>(_indi).GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift) &&
                   dynamic_cast<Indi_WPR *>(_indi).GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift + 1);
        break;
      default:
        break;
    }
    return _result;
  }

  /**
   * Event on strategy's init.
   */
  void OnInit() {
    // Initialize indicators.
    switch (Oscillator_Type) {
      case STG_OSCILLATOR_TYPE_AC:  // AC
      {
        IndiACParams ac_params(::Oscillator_Indi_AC_Shift);
        ac_params.SetTf(Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
        ac_params.SetDataSourceType(Oscillator_Indi_AC_SourceType);
        SetIndicator(new Indi_AC(ac_params), ::Oscillator_Type);
        break;
      }
      case STG_OSCILLATOR_TYPE_AD:  // AD
      {
        IndiADParams ad_params(::Oscillator_Indi_AD_Shift);
        ad_params.SetDataSourceType(Oscillator_Indi_AD_SourceType);
        ad_params.SetTf(Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
        SetIndicator(new Indi_AD(ad_params), ::Oscillator_Type);
        break;
      }
      case STG_OSCILLATOR_TYPE_RSI:  // RSI
      {
        IndiRSIParams _indi_params(::Oscillator_Indi_RSI_Period, ::Oscillator_Indi_RSI_Applied_Price,
                                   ::Oscillator_Indi_RSI_Shift);
        _indi_params.SetTf(Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
        SetIndicator(new Indi_RSI(_indi_params), ::Oscillator_Type);
        break;
      }
      case STG_OSCILLATOR_TYPE_STOCH:  // Stochastic
      {
        IndiStochParams _indi_params(::Oscillator_Indi_Stochastic_KPeriod, ::Oscillator_Indi_Stochastic_DPeriod,
                                     ::Oscillator_Indi_Stochastic_Slowing, ::Oscillator_Indi_Stochastic_MA_Method,
                                     ::Oscillator_Indi_Stochastic_Price_Field, ::Oscillator_Indi_Stochastic_Shift);
        _indi_params.SetTf(Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
        SetIndicator(new Indi_Stochastic(_indi_params), ::Oscillator_Type);
        break;
      }
      case STG_OSCILLATOR_TYPE_WPR:  // WPR
      {
        IndiWPRParams _indi_params(::Oscillator_Indi_WPR_Period, ::Oscillator_Indi_WPR_Shift);
        _indi_params.SetTf(Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
        SetIndicator(new Indi_WPR(_indi_params), ::Oscillator_Type);
        break;
      }
      case STG_OSCILLATOR_TYPE_0_NONE:  // (None)
      default:
        break;
    }
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method, float _level = 0.0f, int _shift = 0) {
    IndicatorBase *_indi = GetIndicator(::Oscillator_Type);
    // uint _ishift = _indi.GetShift();
    bool _result = Oscillator_Type != STG_OSCILLATOR_TYPE_0_NONE && IsValidEntry(_indi, _shift);
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        // Buy signal.
        _result &= _indi.IsIncreasing(1, 0, _shift);
        _result &= _indi.IsIncByPct(_level, 0, _shift, 2);
        if (_result && _method != 0) {
          if (METHOD(_method, 0)) _result &= _indi.IsDecreasing(1, 0, _shift + 1);
          if (METHOD(_method, 1)) _result &= _indi.IsIncreasing(4, 0, _shift + 3);
          if (METHOD(_method, 2))
            _result &= fmax4(_indi[_shift][0], _indi[_shift + 1][0], _indi[_shift + 2][0], _indi[_shift + 3][0]) ==
                       _indi[_shift][0];
        }
        break;
      case ORDER_TYPE_SELL:
        // Sell signal.
        _result &= _indi.IsDecreasing(1, 0, _shift);
        _result &= _indi.IsDecByPct(_level, 0, _shift, 2);
        if (_result && _method != 0) {
          if (METHOD(_method, 0)) _result &= _indi.IsIncreasing(1, 0, _shift + 1);
          if (METHOD(_method, 1)) _result &= _indi.IsDecreasing(4, 0, _shift + 3);
          if (METHOD(_method, 2))
            _result &= fmin4(_indi[_shift][0], _indi[_shift + 1][0], _indi[_shift + 2][0], _indi[_shift + 3][0]) ==
                       _indi[_shift][0];
        }
        break;
    }
    return _result;
  }
};
