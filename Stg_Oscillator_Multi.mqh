/**
 * @file
 * Implements Oscillator_Multi strategy based on the Oscillator_Multi indicator.
 */

enum ENUM_STG_OSCILLATOR_MULTI_TYPE {
  STG_OSCILLATOR_MULTI_TYPE_0_NONE = 0,  // (None)
  STG_OSCILLATOR_MULTI_TYPE_ADX,         // ADX
  STG_OSCILLATOR_MULTI_TYPE_ADXW,        // ADXW
};

// User input params.
INPUT_GROUP("Oscillator_Multi strategy: main strategy params");
INPUT ENUM_STG_OSCILLATOR_MULTI_TYPE Oscillator_Multi_Type = STG_OSCILLATOR_MULTI_TYPE_ADX;  // Oscillator type
INPUT_GROUP("Oscillator_Multi strategy: strategy params");
INPUT float Oscillator_Multi_LotSize = 0;                // Lot size
INPUT int Oscillator_Multi_SignalOpenMethod = 6;         // Signal open method
INPUT float Oscillator_Multi_SignalOpenLevel = 0;        // Signal open level
INPUT int Oscillator_Multi_SignalOpenFilterMethod = 32;  // Signal open filter method
INPUT int Oscillator_Multi_SignalOpenFilterTime = 3;     // Signal open filter time (0-31)
INPUT int Oscillator_Multi_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT int Oscillator_Multi_SignalCloseMethod = 0;        // Signal close method
INPUT int Oscillator_Multi_SignalCloseFilter = 32;       // Signal close filter (-127-127)
INPUT float Oscillator_Multi_SignalCloseLevel = 0;       // Signal close level
INPUT int Oscillator_Multi_PriceStopMethod = 0;          // Price limit method
INPUT float Oscillator_Multi_PriceStopLevel = 2;         // Price limit level
INPUT int Oscillator_Multi_TickFilterMethod = 32;        // Tick filter method (0-255)
INPUT float Oscillator_Multi_MaxSpread = 4.0;            // Max spread to trade (in pips)
INPUT short Oscillator_Multi_Shift = 0;                  // Shift
INPUT float Oscillator_Multi_OrderCloseLoss = 80;        // Order close loss
INPUT float Oscillator_Multi_OrderCloseProfit = 80;      // Order close profit
INPUT int Oscillator_Multi_OrderCloseTime = -30;         // Order close time in mins (>0) or bars (<0)
INPUT_GROUP("Oscillator Multi strategy: ADX indicator params");
INPUT int Oscillator_Multi_Indi_ADX_Period = 16;                                    // Averaging period
INPUT ENUM_APPLIED_PRICE Oscillator_Multi_Indi_ADX_AppliedPrice = PRICE_TYPICAL;    // Applied price
INPUT int Oscillator_Multi_Indi_ADX_Shift = 0;                                      // Shift
INPUT ENUM_IDATA_SOURCE_TYPE Oscillator_Multi_Indi_ADX_SourceType = IDATA_BUILTIN;  // Source type
INPUT_GROUP("Oscillator Multi strategy: ADXW indicator params");
INPUT int Oscillator_Multi_Indi_ADXW_Period = 16;                                    // Averaging period
INPUT ENUM_APPLIED_PRICE Oscillator_Multi_Indi_ADXW_AppliedPrice = PRICE_TYPICAL;    // Applied price
INPUT int Oscillator_Multi_Indi_ADXW_Shift = 0;                                      // Shift
INPUT ENUM_IDATA_SOURCE_TYPE Oscillator_Multi_Indi_ADXW_SourceType = IDATA_BUILTIN;  // Source type

// Structs.

// Defines struct with default user strategy values.
struct Stg_Oscillator_Multi_Params_Defaults : StgParams {
  Stg_Oscillator_Multi_Params_Defaults()
      : StgParams(::Oscillator_Multi_SignalOpenMethod, ::Oscillator_Multi_SignalOpenFilterMethod,
                  ::Oscillator_Multi_SignalOpenLevel, ::Oscillator_Multi_SignalOpenBoostMethod,
                  ::Oscillator_Multi_SignalCloseMethod, ::Oscillator_Multi_SignalCloseFilter,
                  ::Oscillator_Multi_SignalCloseLevel, ::Oscillator_Multi_PriceStopMethod,
                  ::Oscillator_Multi_PriceStopLevel, ::Oscillator_Multi_TickFilterMethod, ::Oscillator_Multi_MaxSpread,
                  ::Oscillator_Multi_Shift) {
    Set(STRAT_PARAM_LS, Oscillator_Multi_LotSize);
    Set(STRAT_PARAM_OCL, Oscillator_Multi_OrderCloseLoss);
    Set(STRAT_PARAM_OCP, Oscillator_Multi_OrderCloseProfit);
    Set(STRAT_PARAM_OCT, Oscillator_Multi_OrderCloseTime);
    Set(STRAT_PARAM_SOFT, Oscillator_Multi_SignalOpenFilterTime);
  }
};

class Stg_Oscillator_Multi : public Strategy {
 public:
  Stg_Oscillator_Multi(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_Oscillator_Multi *Init(ENUM_TIMEFRAMES _tf = NULL, EA *_ea = NULL) {
    // Initialize strategy initial values.
    Stg_Oscillator_Multi_Params_Defaults stg_oscillator_multi_defaults;
    StgParams _stg_params(stg_oscillator_multi_defaults);
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams;
    Strategy *_strat = new Stg_Oscillator_Multi(_stg_params, _tparams, _cparams, "Oscillator_Multi");
    return _strat;
  }

  /**
   * Get's oscillator's max modes.
   */
  uint GetMaxModes(IndicatorBase *_indi) {
    bool _result = true;
    switch (Oscillator_Multi_Type) {
      case STG_OSCILLATOR_MULTI_TYPE_ADX:
        _result &= dynamic_cast<Indi_ADX *>(_indi).GetParams().GetMaxModes();
        break;
      case STG_OSCILLATOR_MULTI_TYPE_ADXW:
        _result &= dynamic_cast<Indi_ADXW *>(_indi).GetParams().GetMaxModes();
        break;
      default:
        break;
    }
    return _result;
  }

  /**
   * Validate oscillator's entry.
   */
  bool IsValidEntry(IndicatorBase *_indi, int _shift = 0) {
    bool _result = true;
    switch (Oscillator_Multi_Type) {
      case STG_OSCILLATOR_MULTI_TYPE_ADX:
        _result &= dynamic_cast<Indi_ADX *>(_indi).GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift) &&
                   dynamic_cast<Indi_ADX *>(_indi).GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift + 1);
        break;
      case STG_OSCILLATOR_MULTI_TYPE_ADXW:
        _result &= dynamic_cast<Indi_ADXW *>(_indi).GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift) &&
                   dynamic_cast<Indi_ADXW *>(_indi).GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift + 1);
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
    switch (Oscillator_Multi_Type) {
      case STG_OSCILLATOR_MULTI_TYPE_ADX:  // ADX
      {
        IndiADXParams _adx_params(::Oscillator_Multi_Indi_ADX_Period, ::Oscillator_Multi_Indi_ADX_AppliedPrice,
                                  ::Oscillator_Multi_Indi_ADX_Shift);
        _adx_params.SetDataSourceType(::Oscillator_Multi_Indi_ADX_SourceType);
        _adx_params.SetTf(Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
        SetIndicator(new Indi_ADX(_adx_params), ::Oscillator_Multi_Type);
        break;
      }
      case STG_OSCILLATOR_MULTI_TYPE_ADXW:  // ADXW
      {
        IndiADXWParams _adxw_params(::Oscillator_Multi_Indi_ADXW_Period, ::Oscillator_Multi_Indi_ADXW_AppliedPrice,
                                    ::Oscillator_Multi_Indi_ADXW_Shift);
        _adxw_params.SetDataSourceType(::Oscillator_Multi_Indi_ADXW_SourceType);
        _adxw_params.SetTf(Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
        SetIndicator(new Indi_ADXW(_adxw_params), ::Oscillator_Multi_Type);
        break;
      }
      case STG_OSCILLATOR_MULTI_TYPE_0_NONE:  // (None)
      default:
        break;
    }
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method, float _level = 0.0f, int _shift = 0) {
    IndicatorBase *_indi = GetIndicator(::Oscillator_Multi_Type);
    uint _max_modes = GetMaxModes(_indi);
    // uint _ishift = _indi.GetShift();
    bool _result = Oscillator_Multi_Type != STG_OSCILLATOR_MULTI_TYPE_0_NONE && IsValidEntry(_indi, _shift);
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
