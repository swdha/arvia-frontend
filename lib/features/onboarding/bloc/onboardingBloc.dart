import 'package:bloc/bloc.dart';
import 'onboardingState.dart';
import 'onboardingEvent.dart';
import 'package:diet_app_recovered/features/onboarding/services/storage_service.dart';
import 'package:diet_app_recovered/features/onboarding/models/diet_plan_model.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(OnboardingState()) {
    on<UpdateGoalEvent>((event, emit) {
      final currentList = List<String>.from(state.goals);

      if (currentList.contains(event.goal)) {
        currentList.remove(event.goal);
      } else {
        currentList.add(event.goal);
      }

      print("Current Goals in State: $currentList");

      emit(state.copyWith(goals: currentList));
    });

    on<UpdateActivityEvent>((event, emit) {
      emit(state.copyWith(activity: event.selectedActivity));
    });

    on<UpdateBodyProfileEvent>((event, emit) {
      emit(
        state.copyWith(
          weight: event.weight,
          height: event.height,
          gender: event.gender,
        ),
      );
    });

    on<UpdateTargetWtEvent>((event, emit) {
      emit(state.copyWith(target_weight: event.selectedTargetwt));
    });

    on<UpdateDietEvent>((event, emit) {
      emit(state.copyWith(dietType: event.selectedDiet));
    });

    on<UpdateMedDietEvent>((event, emit) {
      final currentList = List<String>.from(state.medical_diet);

      if (currentList.contains(event.med)) {
        currentList.remove(event.med);
      } else {
        currentList.add(event.med);
      }

      print("Current Med diets in State: $currentList");

      emit(state.copyWith(medical_diet: currentList));
    });

    on<UpdateAllergiesEvent>((event, emit) {
      final currentList = List<String>.from(state.allergies);

      if (currentList.contains(event.selectedAllergies)) {
        currentList.remove(event.selectedAllergies);
      } else {
        currentList.add(event.selectedAllergies);
      }

      print("Current Allergies in State: $currentList");

      emit(state.copyWith(allergies: currentList));
    });

    on<UpdateCuisinesEvent>((event, emit) {
      final currentList = List<String>.from(state.cuisines);

      if (currentList.contains(event.selectedCuisines)) {
        currentList.remove(event.selectedCuisines);
      } else {
        currentList.add(event.selectedCuisines);
      }

      print("Current Cuisines in State: $currentList");

      emit(state.copyWith(cuisines: currentList));
    });

    on<NextStepEvent>((event, emit) {
      if (state.currentStep < 9) {
        print(
          "Moving from step ${state.currentStep} to ${state.currentStep + 1}",
        );
        emit(state.copyWith(currentStep: state.currentStep + 1));
      }
    });

    on<PreviousStepEvent>((event, emit) {
      if (state.currentStep > 0) {
        emit(state.copyWith(currentStep: state.currentStep - 1));
      }
    });

    on<CompleteOnboardingEvent>((event, emit) async {
      List<String> days = [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday",
      ];

      List<DayPlan> fullWeeklyPlan = days
          .map(
            (day) => DayPlan(
              dayName: day,
              totalCalories: 2000,
              totalProtein: 150,
              meals: {
                "breakfast": [
                  MealOption(name: "$day Oats", calories: 300, proteins: 10),
                  MealOption(name: "$day Eggs", calories: 250, proteins: 18),
                ],
                "lunch": [
                  MealOption(
                    name: "Chicken Salad",
                    calories: 500,
                    proteins: 40,
                  ),
                  MealOption(name: "Dal-rice", calories: 420, proteins: 30),
                ],
                "dinner": [
                  MealOption(name: "Paneer", calories: 300, proteins: 20),
                  MealOption(name: "Rice", calories: 200, proteins: 10),
                ],
                "snack": [
                  MealOption(name: "Almonds", calories: 120, proteins: 5),
                  MealOption(name: "Fox-nuts", calories: 200, proteins: 10),
                ],
              },
            ),
          )
          .toList();

      final mockPlan = DietPlanModel(
        generatedDate: DateTime.now().toIso8601String(),
        weeklyPlan: fullWeeklyPlan,
      );

      // Await these so storage is finished before the state changes
      await StorageService().saveDietPlan(mockPlan);
      await StorageService().setOnboardingStatus(true);

      emit(
        state.copyWith(
          onboardingComplete: true,
          dietPlan: mockPlan,

          breakfastIndex: 0,
          lunchIndex: 0,
          dinnerIndex: 0,
          snackIndex: 0,
        ),
      );
    });

    on<SwapMealEvent>((event, emit) {
      final dayCount = state.dietPlan?.weeklyPlan.length ?? 0;
      if (dayCount == 0) return;

      final currentDayIndex = (DateTime.now().weekday - 1) % dayCount;
      final dayPlan = state.dietPlan?.weeklyPlan[currentDayIndex];

      if (dayPlan == null) return;

      if (event.mealType == "breakfast") {
        int nextIndex =
            (state.breakfastIndex + 1) %
            (dayPlan.meals["breakfast"]?.length ?? 1);
        emit(state.copyWith(breakfastIndex: nextIndex));
      } else if (event.mealType == "lunch") {
        int nextIndex =
            (state.lunchIndex + 1) % (dayPlan.meals["lunch"]?.length ?? 1);
        emit(state.copyWith(lunchIndex: nextIndex));
      } else if (event.mealType == "dinner") {
        int nextIndex =
            (state.dinnerIndex + 1) % (dayPlan.meals["dinner"]?.length ?? 1);
        emit(state.copyWith(dinnerIndex: nextIndex));
      } else if (event.mealType == "snack") {
        int nextIndex =
            (state.snackIndex + 1) % (dayPlan.meals["snack"]?.length ?? 1);
        emit(state.copyWith(snackIndex: nextIndex));
      }
    });

    on<LoadSavedPlanEvent>((event, emit) async {
      final savedPlan = await StorageService().getDietPlan();
      final bool isDone = await StorageService().getOnboardingStatus();

      if (savedPlan != null) {
        emit(state.copyWith(onboardingComplete: isDone, dietPlan: savedPlan));
      } else if (isDone) {
        await StorageService().setOnboardingStatus(false);
        emit(state.copyWith(onboardingComplete: false));
      }
    });
  }
}
