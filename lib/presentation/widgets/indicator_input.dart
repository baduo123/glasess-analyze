import 'package:flutter/material.dart';
import '../../core/constants/indicator_standards/indicator_standard_model.dart';

/// 指标输入组件
/// 用于数据录入页面中的指标输入
class IndicatorInput extends StatefulWidget {
  final IndicatorStandard standard;
  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const IndicatorInput({
    super.key,
    required this.standard,
    this.controller,
    this.errorText,
    this.onChanged,
    this.validator,
  });

  @override
  State<IndicatorInput> createState() => _IndicatorInputState();
}

class _IndicatorInputState extends State<IndicatorInput> {
  late TextEditingController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _hasError = widget.errorText != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 12),
            _buildInputField(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.standard.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.standard.isRequired)
                    _buildRequiredBadge(theme),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.standard.description,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (widget.standard.normalRanges.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '参考范围: ${_getReferenceRangeText()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequiredBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '必填',
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInputField(ThemeData theme) {
    final borderRadius = BorderRadius.circular(8);

    return TextFormField(
      controller: _controller,
      keyboardType: _getKeyboardType(),
      decoration: InputDecoration(
        hintText: _getHintText(),
        suffixText: widget.standard.unit.isNotEmpty ? widget.standard.unit : null,
        suffixStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        errorText: widget.errorText,
        border: OutlineInputBorder(
          borderRadius: borderRadius,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: _hasError
                ? theme.colorScheme.error
                : theme.colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: _hasError
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        helperText: _getHelperText(),
        helperStyle: TextStyle(
          fontSize: 11,
          color: theme.colorScheme.outline,
        ),
      ),
      onChanged: widget.onChanged,
      validator: widget.validator ??
          (value) {
            if (widget.standard.isRequired && (value == null || value.isEmpty)) {
              return '${widget.standard.name}不能为空';
            }
            return null;
          },
    );
  }

  TextInputType _getKeyboardType() {
    switch (widget.standard.type) {
      case IndicatorType.numeric:
        return const TextInputType.numberWithOptions(decimal: true);
      case IndicatorType.text:
        return TextInputType.text;
      case IndicatorType.boolean:
        return TextInputType.text;
      default:
        return TextInputType.text;
    }
  }

  String _getHintText() {
    if (widget.standard.minValue != null && widget.standard.maxValue != null) {
      return '${widget.standard.minValue} - ${widget.standard.maxValue}';
    }
    return '请输入${widget.standard.name}';
  }

  String? _getHelperText() {
    if (widget.standard.minValue != null || widget.standard.maxValue != null) {
      return '有效范围: ${widget.standard.minValue ?? "无下限"} - ${widget.standard.maxValue ?? "无上限"}';
    }
    return null;
  }

  String _getReferenceRangeText() {
    if (widget.standard.normalRanges.isEmpty) return '';

    final range = widget.standard.normalRanges.first;
    if (range.min != null && range.max != null) {
      return '${range.min} - ${range.max} ${widget.standard.unit}';
    } else if (range.min != null) {
      return '≥ ${range.min} ${widget.standard.unit}';
    } else if (range.max != null) {
      return '≤ ${range.max} ${widget.standard.unit}';
    }
    return '';
  }
}

/// 快捷输入按钮组
class QuickInputButtons extends StatelessWidget {
  final List<String> values;
  final ValueChanged<String> onSelected;

  const QuickInputButtons({
    super.key,
    required this.values,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        return ActionChip(
          label: Text(value),
          onPressed: () => onSelected(value),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        );
      }).toList(),
    );
  }
}

/// 双眼指标输入组件（左右眼）
class BinocularIndicatorInput extends StatefulWidget {
  final String indicatorName;
  final String unit;
  final TextEditingController? rightController;
  final TextEditingController? leftController;
  final ValueChanged<Map<String, String>>? onChanged;

  const BinocularIndicatorInput({
    super.key,
    required this.indicatorName,
    this.unit = '',
    this.rightController,
    this.leftController,
    this.onChanged,
  });

  @override
  State<BinocularIndicatorInput> createState() => _BinocularIndicatorInputState();
}

class _BinocularIndicatorInputState extends State<BinocularIndicatorInput> {
  late TextEditingController _rightController;
  late TextEditingController _leftController;

  @override
  void initState() {
    super.initState();
    _rightController = widget.rightController ?? TextEditingController();
    _leftController = widget.leftController ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.rightController == null) _rightController.dispose();
    if (widget.leftController == null) _leftController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    if (widget.onChanged != null) {
      widget.onChanged!({
        'right': _rightController.text,
        'left': _leftController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.indicatorName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEyeInput(
                    label: '右眼',
                    icon: Icons.visibility,
                    controller: _rightController,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEyeInput(
                    label: '左眼',
                    icon: Icons.visibility,
                    controller: _leftController,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEyeInput({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            suffixText: widget.unit.isNotEmpty ? widget.unit : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          onChanged: (_) => _notifyChange(),
        ),
      ],
    );
  }
}
